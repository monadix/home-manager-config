{ pkgs, ... }:
let
  # Vieb is no longer packaged in Nixpkgs; use the upstream Linux release.
  pname = "vieb";
  version = "12.10.0";
  src = pkgs.fetchurl {
    url = "https://github.com/Jelmerro/Vieb/releases/download/${version}/Vieb-${version}.AppImage";
    sha256 = "d8485ce40c517e1301395ac9f026b9e363460d4971972af281f99814ed83d306";
  };
  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
  };
in
{
  home.packages = [
    (pkgs.appimageTools.wrapType2 {
      inherit pname version src;
      extraInstallCommands = ''
        install -Dm644 ${appimageContents}/vieb.desktop $out/share/applications/vieb.desktop
        substituteInPlace $out/share/applications/vieb.desktop --replace-fail 'Exec=AppRun' 'Exec=vieb'
        cp -r ${appimageContents}/usr/share/icons $out/share/
      '';
    })
  ];

  xdg.configFile."Vieb/viebrc".text = ''
    colorscheme nord
  '';
  xdg.configFile."Vieb/colors/nord.css".source = ./nord.css;
}
