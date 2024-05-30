{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/56528ee42526794d413d6f244648aaee4a7b56c0.tar.gz") {}
}:

pkgs.mkShell {
 buildInputs = [
    pkgs.bash
    pkgs.cacert
    pkgs.openssh
  ];

  shellHook = ''
  '';
}
