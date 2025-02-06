{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "isaac-box";

  environment.systemPackages = with pkgs; [
    docker-compose
    git
    neovim
    tmux

    # Optional goodies
    direnv
    starship
    zoxide
  ];

  virtualisation.docker.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.mosh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgqUmPrZwBkOtlDgkft1yVL0YoDKdTr6lWvsoNUP6yA"
  ];

  users.users.Isaac-DeFrain = {
    isNormalUser = true;
    useDefaultShell = true;
    createHome = true;
    extraGroups = ["wheel" "docker" "keys"]; # Enable ‘sudo’.
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCYRazgzvBpVsVr6IIAF4ERsVW3/z8NeE750FeomSjKiMGfqP8LY76tpojjnQDNV6kmC9xFp3wy59FkYPFFCIr+lagotlpkF4aA/RLgKGDMOSaGgibbJrhawzWqxIACqzO24qNIRlDAhgZ8SitCb3d+0Xfuf61h7Q1vqw1KIa5zcxihd6Sk7IrljF3l1fnMXGw7jIZ/2toaJ8wJS0tvgajkMN/MtHXNWzhFO+z+2IFzhJmlDfYYQYwVkToscmK4TVj6ji/H79xaYRoK9DZYxzbwKY8ac7cms2cRm+Nt+UBzHKFSzocjaBVuDfyx55VJi0TB4V8b756F5hek9giTcezx"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjLEdzDUNZxefkwTDm7Q6V+nqLX5/yya7MPxG4Fh12hF9jRq8ywjODNV9PXDkOlyxf0gQK67iS81aX5DzLDtP2T1Q8Irw+XrmutwGEA+cCMFwGfebtesd3CxZd3I47UmWgiD0Ba53JGA2kS0NGBCWj6EUyuMD9a6ZJim8AP4NX8TeB37vtCwpf0WTc6wVUNFx/Ee1xqg/k4bXR2n2rB/FtlkxSwW/EtQvmFqIOa5fMqDDK8LODakjt/WCb3XrMgYcKFXv+nbA+pX1aiNciCtB+lOTYY3lDAL+TvRJpG1sOVKJmzKZCx+CqxDpTcs6P380hsvk+TH/4DllhpMDEOigr"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7X5Z5lnnuEgWtYAeOHLw6RSPC/UqLXCiHKoBSk7gbcov6bfjWe4twinCbPikcNDZ3vAY9U3F/35TbJxG6AVYyBKmoDpFG63TM0eZtqo4BucERQlVCF0vxHT64sRjewX7N7xi6vrl8IHufLErrY4ruOAiPI2cQsgyQvdn0g2y2xekXkxeTRDRX3j1DN9X4EoW66knWB/sZXdShs472j9Xs7UGdW3M+q9Z9YfgRGsY2EUCp1Vt0v10h5/nn8hCzCWlhZ23HZnCcJcDvejePVQQYp2r5JMWnlarlZbhO8vddoGi8BnfcEDgxcaIWc0oQfqxCq4Eo5JdXVvMMPVd8wemvtjQwel88NN7STscZAQ31/eU3gSPwCJMKqP0SVJyJ2VCA1QUXH744xBf3Huf7UkFtw6KFmTbbIJiJFSVIlUNyBTiq3gc6Nh6o/lQt1T10LtsrW4gnyOyZc0irQ3KRyXWJXH/SMrvn+kOd/HyUgxEYyrzUw2tv9Zdp0lbB4s+iksix/ePERoWbdp6OokdXJFwfst64up86pgIFvBb3o/6x/NZn0mBd5wntDnjwigFSVzNUzJhwPVw18NLb40ZWCF3MDNJ8bKsUx8awYJqchsMauHC6wU6S3PsovPgTKx9JqTkwhsSEZaxUM07BRfkElrBj9mfOgGGtSbC3mRPJJ3/3VQ=="
    ];
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.trusted-users = ["root" "@wheel"];

  system.stateVersion = "23.11"; # Did NOT change this!
}
