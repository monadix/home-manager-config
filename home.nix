{ config, pkgs, lib, ... }:

{
  home.username = "chell";
  home.homeDirectory = "/home/chell";

  home.stateVersion = "23.05";

  home.packages = with pkgs; [
    brave
    discord
    dmenu
    docker
    droidcam
    evince
    firefox
    gimp
    htop
    jetbrains.idea-community
    kitty
    krita
    libreoffice
    obs-studio
    openshot-qt
    qbittorrent
    scrot
    telegram-desktop
    todoist-electron
    vlc
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  
  xsession = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = ./xmonad/app/Main.hs;
      extraPackages = hPkgs: with hPkgs; [
        random
        dbus
        List
        monad-logger
      ];
    };
  };

  programs = {
  	git = {
	  	enable = true;
    	userName = "chell4";
    	userEmail = "arsenijalfeev@gmail.com";
    };
    
    gh = {
      enable = true;
    };

    tmux = {
      enable = true;
      extraConfig = ''
        set-option -g prefix C-q
        set -g mouse on
      '';
    };

    neovim = 
    let 
      toLua = str: "lua << EOF\n${str}\nEOF\n";
      toLuaFile = file: toLua (builtins.readFile file);
    in {
      enable = true;
      
      extraLuaConfig = builtins.readFile ./nvim/options.lua;
      extraPackages = with pkgs; [
        xclip
      ];

      viAlias = true;
      vimAlias = true;
			vimdiffAlias = true;
    };

    vscode = rec {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        tamasfe.even-better-toml
        haskell.haskell
        bbenoist.nix
        arrterian.nix-env-selector
        rust-lang.rust-analyzer
        asvetliakov.vscode-neovim
      ];
    };
  };

  xdg.mimeApps.defaultApplications = {
    
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
    EDITOR = "vim";
  };

  programs.home-manager.enable = true;
}
