{ config, lib, pkgs, ... }:
let
  buildkitePreBootstrap = pkgs.writeScript "buildkite-pre-bootstrap" ''
    #! /bin/sh
    set -e
    # For debugging:
    if [ -z $BUILDKITE_ENV_FILE ]; then
      echo "No BUILDKITE_ENV_FILE variable set. Env:"
      env
    # else
    #   echo BUILDKITE_ENV_FILE="$BUILDKITE_ENV_FILE"
    #   echo Contents:
    #   cat "$BUILDKITE_ENV_FILE"
    fi
  '';

  buildkiteLaunch = pkgs.writeScript "buildkite-agent-launch" ''
    #!/bin/sh
    set -eu
    buildkite-agent start --config "$HOME"/buildkite-agent.cfg
  '';

  secretsImportScript = pkgs.writeScript "secrets-import" ''
    NETLIFY_AUTH_TOKEN="$(cat /run/keys/netlify-auth-token)"
    export NETLIFY_AUTH_TOKEN
    CLOUDFLARE_ACCOUNT_ID="$(cat /run/keys/cloudflare-account-id)"
    export CLOUDFLARE_ACCOUNT_ID
    CLOUDFLARE_API_TOKEN="$(cat /run/keys/cloudflare-api-token)"
    export CLOUDFLARE_API_TOKEN
  '';

  hooksPath = pkgs.runCommandLocal "buildkite-agent-hooks" {} ''
    mkdir $out
    
    ln -s ${buildkitePreBootstrap} $out/pre-bootstrap

    cat > $out/pre-checkout << EOF
    BUILDKITE_GIT_CLEAN_FLAGS='-ffdx --exclude=rust/target'
    export BUILDKITE_GIT_CLEAN_FLAGS
    EOF

    ln -s ${secretsImportScript} $out/environment
  '';

in
{
  imports = [
    ./nixos-builder-1-ext4-hardware-config.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "nixos-builder-1";

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
    docker-compose
    cloudflared
    git
    neovim
    tmux

    # Optional goodies
    direnv
    starship
    zoxide
  ];

  virtualisation.docker = {
    enable = true;
  };

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
      priority=5
      tags="production=true,nix=true,os-kernel=linux,os-family=nixos,os-variant=nixos,docker=true,xwindows=false,mina-log-storage=true"
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
  users.users.Isaac-DeFrain = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCYRazgzvBpVsVr6IIAF4ERsVW3/z8NeE750FeomSjKiMGfqP8LY76tpojjnQDNV6kmC9xFp3wy59FkYPFFCIr+lagotlpkF4aA/RLgKGDMOSaGgibbJrhawzWqxIACqzO24qNIRlDAhgZ8SitCb3d+0Xfuf61h7Q1vqw1KIa5zcxihd6Sk7IrljF3l1fnMXGw7jIZ/2toaJ8wJS0tvgajkMN/MtHXNWzhFO+z+2IFzhJmlDfYYQYwVkToscmK4TVj6ji/H79xaYRoK9DZYxzbwKY8ac7cms2cRm+Nt+UBzHKFSzocjaBVuDfyx55VJi0TB4V8b756F5hek9giTcezx"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjLEdzDUNZxefkwTDm7Q6V+nqLX5/yya7MPxG4Fh12hF9jRq8ywjODNV9PXDkOlyxf0gQK67iS81aX5DzLDtP2T1Q8Irw+XrmutwGEA+cCMFwGfebtesd3CxZd3I47UmWgiD0Ba53JGA2kS0NGBCWj6EUyuMD9a6ZJim8AP4NX8TeB37vtCwpf0WTc6wVUNFx/Ee1xqg/k4bXR2n2rB/FtlkxSwW/EtQvmFqIOa5fMqDDK8LODakjt/WCb3XrMgYcKFXv+nbA+pX1aiNciCtB+lOTYY3lDAL+TvRJpG1sOVKJmzKZCx+CqxDpTcs6P380hsvk+TH/4DllhpMDEOigr"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7X5Z5lnnuEgWtYAeOHLw6RSPC/UqLXCiHKoBSk7gbcov6bfjWe4twinCbPikcNDZ3vAY9U3F/35TbJxG6AVYyBKmoDpFG63TM0eZtqo4BucERQlVCF0vxHT64sRjewX7N7xi6vrl8IHufLErrY4ruOAiPI2cQsgyQvdn0g2y2xekXkxeTRDRX3j1DN9X4EoW66knWB/sZXdShs472j9Xs7UGdW3M+q9Z9YfgRGsY2EUCp1Vt0v10h5/nn8hCzCWlhZ23HZnCcJcDvejePVQQYp2r5JMWnlarlZbhO8vddoGi8BnfcEDgxcaIWc0oQfqxCq4Eo5JdXVvMMPVd8wemvtjQwel88NN7STscZAQ31/eU3gSPwCJMKqP0SVJyJ2VCA1QUXH744xBf3Huf7UkFtw6KFmTbbIJiJFSVIlUNyBTiq3gc6Nh6o/lQt1T10LtsrW4gnyOyZc0irQ3KRyXWJXH/SMrvn+kOd/HyUgxEYyrzUw2tv9Zdp0lbB4s+iksix/ePERoWbdp6OokdXJFwfst64up86pgIFvBb3o/6x/NZn0mBd5wntDnjwigFSVzNUzJhwPVw18NLb40ZWCF3MDNJ8bKsUx8awYJqchsMauHC6wU6S3PsovPgTKx9JqTkwhsSEZaxUM07BRfkElrBj9mfOgGGtSbC3mRPJJ3/3VQ=="
    ];
  };
  users.users.jhult = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" ];  # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPwpp6p5298n5Ffk7i33uAPVLFdYLbDJFAYPz/9xHjHN"
    ];
  };
  users.users.trevorbernard = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" ];  # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHynx+wu6p1AVG8wbSKCALE+q6tH5e1gxCikrvoY0dJE"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrN7T11bia+XlHEOW7DiWyL8iJitys6RjGM4gZXpFVK"
    ];
  };
  users.users.n1tranquilla = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = [ "wheel" "docker" ];  # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlvbrQLfRCNxi9eprfKiJeT/y2cJ1ix4jwR4RhDqFHK"
    ];
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
