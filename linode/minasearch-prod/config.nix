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

  networking.hostName = "minasearch-prod-green";

  # First, create and configure the tunnel in Cloudflare's dashboard. Then, run:
  # cloudflared tunnel login
  # cloudflared tunnel token --cred-file /root/.cloudflared/tunnel.json minasearch-prod
  #
  services.cloudflared = {
    enable = true;
    user = "root";
    tunnels = {
      "e9c4d3b5-04d7-4575-a6a6-986865217ef2" = {
        credentialsFile = "/run/keys/granola-cloudflare-minasearch-creds-json";
        default = "http_status:404";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    cloudflared
    vim
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
