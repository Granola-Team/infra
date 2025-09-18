{
  description = "NixOS system flake with Flox";

  nixConfig = {
    extra-trusted-substituters = [ "https://cache.flox.dev" ];
    extra-trusted-public-keys = [ "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs=" ];
  };

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs?rev=7ffe0edc685f14b8c635e3d6591b0bbb97365e6c";
    };
    flox = {
      url = "github:flox/flox?rev=b760d17ef27f6d3c158c02a109b118ba5eb49cc9";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flox,
    }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./config.nix
        ];
        specialArgs = { inherit inputs; };
      };
    };
}
