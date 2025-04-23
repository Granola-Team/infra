{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./buildkite.nix
    ./users.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "granola-builder";

  environment.systemPackages = with pkgs; [
    docker-compose
    inputs.flox.packages.${pkgs.system}.default
  ];

  environment.variables = {
    FLOX_USE_SYSTEM_NIX = "1";
  };

  virtualisation.docker.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.git = {
    enable = true;
    lfs.enable = true;
  };
  programs.mosh.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;

  nix.settings.trusted-users = [ "root" "@wheel" ];
  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "23.11"; # Did NOT change this!
}
