{ config, lib, pkgs, inputs, ... }:
let
  buildkitePreBootstrap = pkgs.writeScript "buildkite-pre-bootstrap" ''
    #! /bin/sh
    set -e
    # For debugging:
    if [ -z $BUILDKITE_ENV_FILE ]; then
      echo "No BUILDKITE_ENV_FILE variable set. Env:"
      env
    fi
  '';

  buildkiteLaunch = pkgs.writeScript "buildkite-agent-launch" ''
    #!/bin/sh
    set -eu
    export BUILDKITE_AGENT_TOKEN="$(cat /run/keys/buildkite-agent-token)"
    buildkite-agent start --config "$HOME"/buildkite-agent.cfg
  '';

  hooksPath = pkgs.runCommandLocal "buildkite-agent-hooks" {} ''
    mkdir $out

    ln -s ${buildkitePreBootstrap} $out/pre-bootstrap

    cat > $out/pre-checkout << EOF
    BUILDKITE_GIT_CLEAN_FLAGS='-ffdx --exclude=.cargo'
    export BUILDKITE_GIT_CLEAN_FLAGS
    EOF
  '';

in
{
  systemd.services.buildkite-agent = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      HOME = "/home/bk";
    };
    path = [
      pkgs.buildkite-agent
      pkgs.bash
      pkgs.nix
      inputs.flox.packages.${pkgs.system}.default
      "/run/wrappers"
      "/etc/profiles/per-user/bk"
      "/run/current-system/sw"
    ];
    preStart = ''
      set -u
      cat > "$HOME/buildkite-agent.cfg" <<EOF
      name="builder-%spawn"
      spawn=3
      priority=100
      tags="production=false,flox=true,nix=true,tier1=true,tier2=true,os-kernel=linux,os-family=nixos,os-variant=nixos,docker=true,xwindows=false"
      build-path="$HOME/builds"
      hooks-path="${hooksPath}"
      EOF
    '';
    serviceConfig = {
      User = "bk";
      Group = "keys";
      SupplementaryGroups = "docker";
      ExecStart = buildkiteLaunch;
      RestartSec = 5;
      Restart = "on-failure";
      TimeoutSec = 10;
      TimeoutStopSec = "2 min";
      KillMode = "mixed";
    };
  };

  users.users.bk = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "docker" "keys" ];
    shell = pkgs.bash;
    packages = [ pkgs.buildkite-agent pkgs.bash pkgs.nix pkgs.git-lfs ];
  };
}
