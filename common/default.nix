{ 
  config,
  system,

  pkgs,
  pkgsStable,
  pkgsMaster,

  ... 
}:
{
  home.username = "monadix";
  home.homeDirectory = "/home/monadix";

  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    acpilight
    age
    alsa-utils
    ayugram-desktop
    dig
    vesktop
    dmenu
    docker
    droidcam
    element-desktop
    evince
    feh
    firefox
    pkgsStable.gimp
    gnumake
    htop
    just
    krita
    pkgsStable.libreoffice
    mpv
    obs-studio
    obsidian
    pamixer
    pavucontrol
    python3
    python3Packages.virtualenv
    qbittorrent
    ripgrep
    scrot
    sops
    telegram-desktop
    tor-browser
    vlc
    wineWow64Packages.stableFull
    winetricks
    libxcomposite
    xautolock
    zoom-us

    # fonts
    corefonts
    vista-fonts
  ];

  fonts.fontconfig.enable = true;

  sops.secrets.github-ro-token = {};

  sops.templates."nix-access-tokens.conf".content = ''
    access-tokens = github.com=${config.sops.placeholder.github-ro-token}
  '';

  xdg.configFile."nix/nix.conf".text = ''
    !include ${config.sops.templates."nix-access-tokens.conf".path}
  '';

  services.home-manager.autoExpire = {
    enable = true;
    frequency = "daily";
    timestamp = "-6 months";
  };

  gtk = {
    enable = true;

    theme = {
      package = pkgsStable.nordic;
      name = "Nordic";
    };
    gtk4.theme = config.gtk.theme;

    iconTheme = {
      package = pkgs.nordzy-icon-theme;
      name = "Nordzy-icon";
    };

    cursorTheme = {
      package = pkgs.nordzy-cursor-theme;
      name = "Nordzy-cursors";
    };
  };

  qt = {
    enable = true;

    platformTheme.name = "qtct";
    style.name = "kvantum";

    qt5ctSettings = {
      Appearance = {
        style = "kvantum";
        icon_theme = "Nordzy-icon";
        standard_dialogs = "xdgdesktopportal";
      };
    };

    qt6ctSettings = {
      Appearance = {
        style = "kvantum";
        icon_theme = "Nordzy-icon";
        standard_dialogs = "xdgdesktopportal";
      };
    };

    kvantum = {
      enable = true;

      settings.General.theme = "Nordic";

      themes = [
        pkgs.nordic
      ];
    };
  };

  xdg.configFile."mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "text/html" = "luakit.desktop";
      "x-scheme-handler/http" = "luakit.desktop";
      "x-scheme-handler/https" = "luakit.desktop";
      "x-scheme-handler/about" = "luakit.desktop";
      "x-scheme-handler/unknown" = "luakit.desktop";

      "application/pdf" = "org.gnome.Evince.desktop";

      "x-scheme-handler/tg" = "userapp-AyuGram Desktop-JHY052.desktop";
      "x-scheme-handler/tonsite" = "userapp-AyuGram Desktop-2UJ052.desktop";
    };

    associations.added = {
      "x-scheme-handler/tg" = "userapp-AyuGram Desktop-JHY052.desktop";
      "x-scheme-handler/tonsite" = "userapp-AyuGram Desktop-2UJ052.desktop";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gtk"
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
