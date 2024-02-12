{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "xmonad-dev-shell";
  shellHook = ''
    cabal build
  '';
  packages = with pkgs; [
    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXScrnSaver
    xorg.libXext
  ];
}