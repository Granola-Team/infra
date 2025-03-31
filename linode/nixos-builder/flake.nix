{
  description = "NixOS system flake with flox";

  nixConfig = {
    extra-trusted-substituters = ["https://cache.flox.dev"];
    extra-trusted-public-keys = ["flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flox = {
      url = "github:flox/flox/v1.3.15";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flox,
  }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./config.nix
        # Create a module for flox
        ({
          config,
          lib,
          pkgs,
          ...
        }: {
          options.programs.flox = {
            enable = lib.mkEnableOption "flox";
            useSystemNix = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Configure Flox to use the system's Nix installation";
            };
          };

          config = {
            nix.settings.experimental-features = ["nix-command" "flakes"];

            # Add flox to system packages
            environment.systemPackages = [flox.packages.x86_64-linux.default];

            # Implement the flox configuration
            environment.variables = lib.mkIf (config.programs.flox.enable && config.programs.flox.useSystemNix) {
              FLOX_USE_SYSTEM_NIX = "1";
            };

            systemd.services.buildkite-agent.path = [
              pkgs.buildkite-agent
              pkgs.bash
              pkgs.nix
              flox.packages.x86_64-linux.default
              "/run/wrappers"
              "/etc/profiles/per-user/bk"
              "/run/current-system/sw"
            ];
          };
        })
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
