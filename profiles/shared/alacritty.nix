{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    theme = "nord";
  };

  # Yazi uses this helper for image previews in Alacritty on X11.
  home.packages = [ pkgs.ueberzugpp ];
}
