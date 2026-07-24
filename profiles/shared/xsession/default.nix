{ 
  assets,

  pkgs,
  lib,
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
    enable = true;
    gtk.enable = true;
    x11.enable = true;

    package = pkgs.nordzy-cursor-theme;
    name = "Nordzy-cursors";
  };

  home.file = {
    ".wallpapers" = {
      source = lib.fileset.toSource {
        root = assets.images;
        fileset = assets.images + "/nixos-nord-dark.png";
      };
      recursive = true;
    };

    ".screensaver-imgs" = {
      source = lib.fileset.toSource {
        root = assets.images;
        fileset = lib.fileset.unions (builtins.map (path: assets.images + ("/" + path)) [
          "ant-funny-sad.jpg"
          "finally-good-tech.jpg"
          "funny-sad-ant.jpeg"
          "gopher.jpg"
          "john-goida.jpg"
          "me(literally).jpg"
          "more-try-from.jpg"
          "my-dreams.jpg"
          "nazixos.jpg"
          "surgut-sushestvuyet.jpg"
          "я(блоко).jpg"
        ]);
      };
      recursive = true;
    };

    ".xscreensaver" = {
      source = ./xscreensaver;
    };
  };
}
