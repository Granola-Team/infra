let
  pkgs =
    import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/878ef7d9721bee9f81f8a80819f9211ad1f993da.tar.gz") { };
in {
  network = {
    inherit pkgs;
    description = "simple hosts";
  };

  "linode-nixos2" = { config, pkgs, lib, ... }: {
    imports = [
      ./nixos2-config.nix
    ];
    deployment.targetUser = "granola";
    deployment.targetHost = "192.53.120.145";
  };
}
