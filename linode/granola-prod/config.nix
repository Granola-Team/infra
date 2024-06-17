{ config, lib, pkgs, ... }:
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
    buildkite-agent start --config "$HOME"/buildkite-agent.cfg
  '';

  secretsImportScript = pkgs.writeScript "secrets-import" ''
    #! /bin/sh
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
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "granola-prod";

  # For the mina-indexer:
  #
  # First, run:
  # nix-env -iA nixos.cloudflared
  # cloudflared tunnel login
  # cloudflared tunnel token --cred-file /root/.cloudflared/tunnel.json nixos-builder-1
  #
  services.cloudflared = {
    enable = true;
    user = "root";
    tunnels = {
      "950210ce-d5a3-477e-b4e0-2b097732110c" = {
        credentialsFile = "${config.users.users.root.home}/.cloudflared/tunnel.json";
        default = "http_status:404";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    cloudflared
    git
    neovim
    tmux

    # Optional goodies
    direnv
    starship
    zoxide
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;
  programs.mosh.enable = true;

  users.defaultUserShell = pkgs.zsh;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
  ];

  users.users.bk = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "keys" ];
    shell = pkgs.bash;
    packages = [ pkgs.buildkite-agent pkgs.bash pkgs.nix ];
  };

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
      "/run/wrappers"
      "/etc/profiles/per-user/bk"
      "/run/current-system/sw"
    ];
    preStart = ''
      set -u
      cat > "$HOME/buildkite-agent.cfg" <<EOF
      token="$(cat /run/keys/buildkite-agent-token)"
      name="prod-%spawn"
      spawn=2
      priority=1
      tags="production=true,nix=true,os-kernel=linux,os-family=nixos,os-variant=nixos,docker=false,xwindows=false,mina-logs=false,kvm=false"
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
    };
  };

  users.users.jhult = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = [ "wheel" ];  # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPwpp6p5298n5Ffk7i33uAPVLFdYLbDJFAYPz/9xHjHN"
    ];
  };
  users.users.robinbb = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = [ "wheel" "keys" ];  # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  system.stateVersion = "23.11"; # Did NOT change this!
}
