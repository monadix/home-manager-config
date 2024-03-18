{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "xmonad-dev-shell";
  shellHook = ''
    code .
  '';
  packages = with pkgs; [
    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXScrnSaver
    xorg.libXext

    ghc
  ];
}
