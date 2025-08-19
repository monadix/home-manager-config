{ lib, pkgsMaster, ... }:
{
  programs.qutebrowser = {
    enable = true;

    settings = 
    let 
      pref = {
        colors.webpage.preferred_color_scheme = "dark";

        content.pdfjs = true;

        downloads.location = {
          directory = "~/Downloads/qute/";
          prompt = false;
        };

        auto_save.session = true;
      };
      nordTheme = import ./nord-theme.nix;
    in lib.attrsets.recursiveUpdate pref nordTheme;

    keyBindings = {
      normal = {
        "o" = "cmd-set-text -s :open -s";
        "O" = "cmd-set-text -s :open -ts";
      };
    };
  };
}
