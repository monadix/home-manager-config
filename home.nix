{ pkgs
, pkgsStable
, nix-vscode-extensions
,
... }:

{
  home.username = "chell";
  home.homeDirectory = "/home/chell";

  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    acpilight
    ayugram-desktop
    brave
    code-cursor
    #discord
    dmenu
    docker
    droidcam
    element-desktop
    evince
    feh
    firefox
    gimp
    gnumake
    htop
    jetbrains.idea-community
    krita
    libreoffice
    mpv
    obs-studio
    obsidian
    pkgsStable.openshot-qt
    pavucontrol
    postman
    qbittorrent
    scrot
    telegram-desktop
    todoist-electron
    tor-browser
    vlc
    wineWowPackages.stable
    winetricks
    xorg.libXcomposite
    xautolock
    zoom-us

    # fonts
    corefonts
    vistafonts
  ];

  fonts.fontconfig.enable = true;

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "jitsi-meet-1.0.8043"
      ];
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

  xdg = {
    portal = {
      enable = true;
      xdgOpenUsePortal = true;

      config = {
        common = {
          default = "*";
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
        };
      };

      extraPortals = with pkgs; [
        xdg-desktop-portal-termfilechooser
      ];
    };

    mimeApps.defaultApplications = {
    };
  };

  home.file = {
    ".config/xdg-desktop-portal-termfilechooser/config" = {
      source = ./termfilechooser.conf;
    };
    ".config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh" = {
      source = ./yazi-wrapper.sh;
      executable = true;
    };
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
