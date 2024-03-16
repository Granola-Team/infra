let pkgs = import <nixpkgs> { };
in {
  network = {
    inherit pkgs;
    description = "simple hosts";
    ordering = { tags = [ "linode-nixos2" ]; };
  };

  "linode-nixos2" = { config, pkgs, lib, ... }: {
    imports = [
      ./configuration.nix
    ];
    deployment.tags = [ "linode-nixos2" ];
    deployment.targetUser = "root";
    deployment.targetHost = "192.53.120.145";
  };
}
