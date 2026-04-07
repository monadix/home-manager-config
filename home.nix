{ 
  config,
  system,

  pkgs,
  pkgsStable,
  pkgsMaster,

  nix-vscode-extensions,
  sops-nix,

  ... 
}:
{
  home.username = "chell";
  home.homeDirectory = "/home/chell";

  home.stateVersion = "23.05";

  imports = [
    sops-nix.homeManagerModules.sops
  ];

  home.packages = with pkgs; [
    acpilight
    age
    alsa-utils
    ayugram-desktop
    pkgsStable.code-cursor
    dig
    discord
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
    jetbrains.idea-oss
    krita
    pkgsStable.libreoffice
    mpv
    obs-studio
    obsidian
    pamixer
    pavucontrol
    python3
    qbittorrent
    ripgrep
    scrot
    sops
    telegram-desktop
    tor-browser
    vlc
    wineWow64Packages.stable
    winetricks
    libxcomposite
    xautolock
    zoom-us

    # fonts
    corefonts
    vista-fonts
  ];

  fonts.fontconfig.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      nix-vscode-extensions.overlays.default
    ];
  };
  
  services.home-manager.autoExpire = {
    enable = true;
    frequency = "daily";
    timestamp = "-6 months";
  };

  gtk = {
    enable = true;

    theme = {
      package = pkgs.nordic;
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


  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "text/html" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/about" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/unknown" = "org.qutebrowser.qutebrowser.desktop";

      "application/pdf" = "org.gnome.Evince.desktop";

      "x-scheme-handler/tg" = "userapp-AyuGram Desktop-JHY052.desktop";
      "x-scheme-handler/tonsite" = "userapp-AyuGram Desktop-2UJ052.desktop";
    };

    associations.added = {
      "x-scheme-handler/tg" = "userapp-AyuGram Desktop-JHY052.desktop";
      "x-scheme-handler/tonsite" = "userapp-AyuGram Desktop-2UJ052.desktop";
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
