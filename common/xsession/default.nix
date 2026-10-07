{ 
  assets,

  pkgs,
  lib,
  ... 
}:
{
  xsession = {
    enable = true;
    
    initExtra = ''
      ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ~/.wallpapers/nixos-nord-dark.png &
      ${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent &

      ${pkgs.xidlehook}/bin/xidlehook \
        --not-when-audio \
        --timer 1800 \
        'systemctl suspend' \
        ''' &
    '';

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

  systemd.user.services.xscreensaver-keyboard-layout = {
    Unit = {
      Description = "Set US keyboard layout when XScreenSaver locks";
      Requires = [ "xscreensaver.service" ];
      After = [ "graphical-session.target" "xscreensaver.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = pkgs.writeShellScript "xscreensaver-keyboard-layout" ''
        ${pkgs.xscreensaver}/bin/xscreensaver-command --watch |
        while read -r event _; do
          if [ "$event" = LOCK ]; then
            ${pkgs.xkb-switch}/bin/xkb-switch -s us
          fi
        done
      '';

      Restart = "on-failure";
      RestartSec = 1;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = with pkgs; [
    xkb-switch
  ];

  home.keyboard = {
    layout = "us,ru";
    variant = ",";
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;

    package = pkgs.nordzy-cursor-theme;
    name = "Nordzy-cursors";
  };

  home.file = {
    ".xmonad/xmonad-${pkgs.stdenv.hostPlatform.system}".force = true;

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
          "funny-sova.jpg"
          "ye.jpg"
        ]);
      };
      recursive = true;
    };

    ".xscreensaver" = {
      source = ./xscreensaver;
    };
  };
}
