{ pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./buildkite.nix
    ./users.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "tier3-builder";

  environment.systemPackages = with pkgs; [
    docker-compose
    vim
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };
  programs.mosh.enable = true;
  programs.tmux.enable = true;
  programs.zsh.enable = true;

  virtualisation.docker.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # The large 'nofile' value is required for the mina-indexer.
  security.pam.loginLimits = [
    { domain = "*"; item = "nofile"; type = "-"; value = "1234567"; }
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  system.stateVersion = "23.11"; # Did NOT change this!
}
