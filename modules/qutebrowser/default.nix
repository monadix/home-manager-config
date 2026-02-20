{ lib, ... }:
{
  programs.qutebrowser = {
    enable = true;

    settings = {
      colors.webpage.preferred_color_scheme = "dark";

      content.pdfjs = true;

      downloads.location = {
        directory = "~/Downloads/qute/";
        prompt = false;
      };

      auto_save.session = true;

      qt.args = [ "disable-features=PermissionElement" ];
    };

    keyBindings = {
      normal = {
        "o" = "cmd-set-text -s :open -s";
        "O" = "cmd-set-text -s :open -ts";
      };
    };
  };
}
