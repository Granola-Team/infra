{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./buildkite.nix
    ./users.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "minasearch-prod";

  # For the mina-indexer:
  #
  # First, run:
  # nix-env -iA nixos.cloudflared
  # cloudflared tunnel login
  # cloudflared tunnel token --cred-file /root/.cloudflared/tunnel.json nixos-builder-1
  #
  services.cloudflared = {
    enable = false;
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
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = false;
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "1234567"; }
  ];

  systemd.tmpfiles.rules = [
    "d /mnt 0777 root root"
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };
  programs.mosh.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  system.stateVersion = "23.11"; # Do NOT change this!
}
