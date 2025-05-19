{ ... }:
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

    keyBindings = {
      normal = {
        "o" = "cmd-set-text -s :open -s";
        "O" = "cmd-set-text -s :open -ts";
      };
    };
  };
}
