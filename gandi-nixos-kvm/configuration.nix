{ config, pkgs, ... }:
{
  imports =
    [ <nixpkgs/nixos/modules/virtualisation/openstack-config.nix>
    ];

  services.buildkite-agents."gandi-nixos" = {
    enable = true;
    name = "gandi-nixos";
    tokenPath = "/run/keys/buildkite-token";  # Requires manual install!
    extraConfig = "spawn=6";
    tags = {
      kvm = "true";
    };
  };

  # Hackery required because there's no other way to 'loginctl enable-linger'
  # for the buildkite agent.
  #
  systemd.tmpfiles.rules = [
    "f /var/lib/systemd/linger/buildkite-agent-gandi-nixos"
  ];

  # Need to figure out how to run this automatically:
  # usermod --add-subuids 100000-165535 --add-subgids 100000-165535 buildkite-agent-gandi-nixos
  environment.etc = {
    subuid = {
      text = "buildkite-agent-gandi-nixos:100000:65536";
      mode = "0644";
    };
    subgid = {
      text = "buildkite-agent-gandi-nixos:100000:65536";
      mode = "0644";
    };
  };

  boot.isContainer = true;

  environment.systemPackages = with pkgs; [
    vim
    tmux
  ];

  programs.mosh.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
