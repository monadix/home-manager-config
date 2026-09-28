{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    theme = "nord";
    settings.env.WINIT_X11_SCALE_FACTOR = "1.0";
  };

  # Yazi uses this helper for image previews in Alacritty on X11.
  home.packages = [ pkgs.ueberzugpp ];
}
