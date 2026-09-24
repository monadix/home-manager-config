{
  config,
  lib,
  pkgs,
  ...
}:
let
  termfilechooser = pkgs.xdg-desktop-portal-termfilechooser;
in
{
  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;

    shellWrapperName = "y";

    keymap = {
      mgr.prepend_keymap = [
        { 
          run  = ''shell "$SHELL" --block'';
          on   = [ "!" ];
          desc = "Open $SHELL here";
        }
      ];
    };
  };

  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=${termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
    create_help_file=1
    default_dir=${config.home.homeDirectory}/Downloads
    env=TERMCMD=${lib.getExe pkgs.kitty} --class termfilechooser --title termfilechooser
    env=PATH=${lib.makeBinPath [
      pkgs.yazi
      pkgs.gnused
    ]}:$PATH
    open_mode=suggested
    save_mode=suggested
  '';

  xdg.portal = {
    extraPortals = [ termfilechooser ];
    config.common."org.freedesktop.impl.portal.FileChooser" = [
      "termfilechooser"
    ];
  };

  home.sessionVariables.GTK_USE_PORTAL = "1";
}
