{ pkgs, ... }:
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

  secretsImportScript = pkgs.writeScript "secrets-import" ''
    #! /bin/sh
    set -eu
    LINODE_OBJ_ACCESS_KEY="$(cat /run/keys/linode-access-key)"
    export LINODE_OBJ_ACCESS_KEY
    LINODE_OBJ_SECRET_KEY="$(cat /run/keys/linode-secret-key)"
    export LINODE_OBJ_SECRET_KEY
  '';

  hooksPath = pkgs.runCommandLocal "buildkite-agent-hooks" {} ''
    mkdir $out

    ln -s ${buildkitePreBootstrap} $out/pre-bootstrap

    cat > $out/pre-checkout << EOF
    BUILDKITE_GIT_CLEAN_FLAGS='-ffdx'
    export BUILDKITE_GIT_CLEAN_FLAGS
    EOF

    ln -s ${secretsImportScript} $out/environment
  '';

in
{
  users.users.bk = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "keys" ];
    shell = pkgs.bash;
    packages = [ pkgs.buildkite-agent ];
  };

  systemd.services.buildkite-agent = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      HOME = "/home/bk";
    };
    path = [
      pkgs.buildkite-agent
      "/etc/profiles/per-user/bk"
      "/run/current-system/sw"
    ];
    preStart = ''
      set -u
      cat > "$HOME/buildkite-agent.cfg" <<EOF
      name="minasearch-prod-blue"
      spawn=1
      priority=1
      tags="minasearch-prod=blue,nix=true,os-kernel=linux,os-family=nixos,os-variant=nixos"
      build-path="$HOME/builds"
      hooks-path="${hooksPath}"
      EOF
    '';
    serviceConfig = {
      User = "bk";
      Group = "keys";
      ExecStart = buildkiteLaunch;
      RestartSec = 5;
      Restart = "on-failure";
      TimeoutSec = 10;
      TimeoutStopSec = "2 min";
      KillMode = "mixed";
      LimitNOFILE = 123456;
    };
  };
}
