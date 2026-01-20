{ 
  system,

  pkgs,
  pkgsStable,
  pkgsMaster,

  nix-vscode-extensions,

  ... 
}:
{
  home.username = "chell";
  home.homeDirectory = "/home/chell";

  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    acpilight
    alsa-utils
    ayugram-desktop
    code-cursor
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
    pkgsStable.jetbrains.idea-community
    krita
    libreoffice
    mpv
    obs-studio
    obsidian
    pavucontrol
    qbittorrent
    scrot
    telegram-desktop
    tor-browser
    vlc
    wineWowPackages.stable
    winetricks
    xorg.libXcomposite
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

  home.file = {
    
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/chell/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
}
