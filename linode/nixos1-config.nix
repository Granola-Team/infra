{ config, lib, pkgs, ... }:
let
  environmentHookScript = pkgs.writeScript "buildkite-env-hook" ''
    NETLIFY_AUTH_TOKEN="$(cat /run/keys/netlify-auth-token)"
    export NETLIFY_AUTH_TOKEN
  '';
  hooksPath = pkgs.runCommandLocal "buildkite-agent-hooks" {} ''
    mkdir $out
    ln -s ${environmentHookScript} $out/environment
  '';
  buildkiteLaunch = pkgs.writeScript "buildkite-agent-launch" ''
    #!/bin/sh
    set -eu
    buildkite-agent start --config "$HOME"/buildkite-agent.cfg
  '';
in
{
  imports = [
    ./nixos1-ext4-hardware-config.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "nixos1"; # Define your hostname.

  environment.systemPackages = with pkgs; [
    docker-compose
    git
    mosh
    neovim
    tmux

    # Optional goodies
    direnv
    starship
    zoxide
  ];

  virtualisation.docker = {
    enable = true;
    # rootless.enable = true;
    # rootless.setSocketVariable = true;
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;

  users.defaultUserShell = pkgs.zsh;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
  ];

  users.users.bk = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "docker" "keys" ];
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
      name="bk1-%spawn"
      spawn=3
      priority=6
      tags="os=linux,kvm=true,docker=true,xwindows=false"
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

  users.users.granola = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" "keys" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
    ];
    linger = true;
  };
  users.users.robinbb = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" "keys" ];  # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  system.stateVersion = "23.11"; # Did NOT change this!
}
