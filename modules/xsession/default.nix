{ pkgs
,
... }:
{
  xsession = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = ./xmonad.hs;
      extraPackages = hPkgs: with hPkgs; [
        dbus
        List
        monad-logger
        random
        time
      ];
    };
  };

  home.pointerCursor = {
    package = pkgs.nordzy-cursor-theme;
    name = "Nordzy-cursors";
  };

  home.file = {
    ".wallpapers" = {
      source = ./wallpapers;
      recursive = true;
    };
  };
}
