{ config
, 
... }:
{
  programs.qutebrowser = {
    enable = true;

    settings = {
      colors.webpage.preferred_color_scheme = "dark";

      downloads.location = {
        directory = "~/Downloads/qute/";
        prompt = false;
      };
    };
  };
}
