{ config, lib, pkgs, ... }:

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

  services.buildkite-agents.bk1 = {
    enable = true;
    name = "bk1-%n";
    tokenPath = "/run/keys/buildkite-agent-token";
    runtimePackages = [ pkgs.bash pkgs.git pkgs.nix ];
    tags = {
      kvm = "true";
      os = "linux";
      docker = "true";
      xwindows = "false";
    };
    hooks = {
      environment = ''
        NETLIFY_AUTH_TOKEN="$(cat /run/keys/netlify-auth-token)"
        export NETLIFY_AUTH_TOKEN
      '';
    };
    extraConfig = ''
      # The number of agents to spawn in parallel (default is "1")
      spawn=3

      # The priority of the agent (higher priorities are assigned work first)
      priority=5
    '';
  };

  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;

  users.defaultUserShell = pkgs.zsh;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
  ];
  users.users.buildkite-agent-bk1.extraGroups = [ "docker" ];
  users.users.granola = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
    ];
    linger = true;
  };
  users.users.robinbb = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" ];  # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  system.stateVersion = "23.11"; # Did NOT change this!
}
