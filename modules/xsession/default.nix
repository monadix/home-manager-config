{ 
  pkgs,
  ... 
}:
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

  services = {
    xscreensaver = {
      enable = true;
    };

    screen-locker = {
      enable = true;
      lockCmd = "xscreensaver-command --lock";
      xautolock.enable = true;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;

    package = pkgs.nordzy-cursor-theme;
    name = "Nordzy-cursors";
  };

  home.file = {
    ".wallpapers" = {
      source = ./wallpapers;
      recursive = true;
    };

    ".screensaver-imgs" = {
      source = ./screensaver-imgs;
      recursive = true;
    };

    ".xscreensaver" = {
      source = ./xscreensaver;
    };
  };
}
