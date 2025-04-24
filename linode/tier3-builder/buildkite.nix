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
    set -eu
    NETLIFY_AUTH_TOKEN="$(cat /run/keys/netlify-auth-token)"
    export NETLIFY_AUTH_TOKEN
    CLOUDFLARE_ACCOUNT_ID="$(cat /run/keys/cloudflare-account-id)"
    export CLOUDFLARE_ACCOUNT_ID
    CLOUDFLARE_API_TOKEN="$(cat /run/keys/cloudflare-api-token)"
    export CLOUDFLARE_API_TOKEN
    LINODE_OBJ_ACCESS_KEY="$(cat /run/keys/linode-access-key)"
    export LINODE_OBJ_ACCESS_KEY
    LINODE_OBJ_SECRET_KEY="$(cat /run/keys/linode-secret-key)"
    export LINODE_OBJ_SECRET_KEY
    GRANOLA_GH_PUBLIC_KEY="$(cat /run/keys/granola-gh-public-key)"
    export GRANOLA_GH_PUBLIC_KEY
    GRANOLA_GH_SECRET_KEY="$(cat /run/keys/granola-gh-secret-key)"
    export GRANOLA_GH_SECRET_KEY
  '';

  hooksPath = pkgs.runCommandLocal "buildkite-agent-hooks" { } ''
    mkdir $out

    ln -s ${buildkitePreBootstrap} $out/pre-bootstrap

    cat > $out/pre-checkout << EOF
    BUILDKITE_GIT_CLEAN_FLAGS='-ffdx --exclude=.cargo'
    export BUILDKITE_GIT_CLEAN_FLAGS
    EOF

    ln -s ${secretsImportScript} $out/environment
  '';
in
{
  users.users.bk = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [
      "docker"
      "keys"
    ];
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
      name="mina-indexer-tier3-builder"
      spawn=1
      priority=100
      tags="production=false,tier1=false,tier2=false,tier3=true,nix=true,os-kernel=linux,os-family=nixos,os-variant=nixos,docker=true,xwindows=false"
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
      LimitNOFILE = 123456;
    };
  };
}
