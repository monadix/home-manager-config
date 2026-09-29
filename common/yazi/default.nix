{
  config,
  lib,
  pkgs,
  ...
}:
let
  termfilechooser = pkgs.xdg-desktop-portal-termfilechooser;
  yaziFileChooser = pkgs.writeShellScript "yazi-file-chooser" ''
    set -eu

    multiple="$1"
    directory="$2"
    save="$3"
    path="$4"
    out="$5"
    debug="''${6:-0}"

    if [[ "$debug" == "1" ]]; then
      set -x
    fi

    if [[ "$save" == "1" ]]; then
      args=(--chooser-file="$out" "$path")
    elif [[ "$directory" == "1" ]]; then
      args=(--chooser-file="$out" --cwd-file="$out.1" "$path")
    elif [[ "$multiple" == "1" ]]; then
      args=(--chooser-file="$out" "$path")
    else
      args=(--chooser-file="$out" "$path")
    fi

    export PATH=${lib.makeBinPath [
      pkgs.yazi
      pkgs.ueberzugpp
    ]}:"$PATH"

    ${lib.getExe pkgs.alacritty} \
      --class termfilechooser \
      --title termfilechooser \
      -e ${lib.getExe pkgs.yazi} "''${args[@]}"

    if [[ "$directory" == "1" ]]; then
      cwd_out="$out.1"
      if [[ ! -s "$out" && -s "$cwd_out" ]]; then
        ${pkgs.coreutils}/bin/cat "$cwd_out" > "$out"
      fi
      ${pkgs.coreutils}/bin/rm -f "$cwd_out"
    fi
  '';
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
    cmd=${yaziFileChooser}
    create_help_file=1
    default_dir=${config.home.homeDirectory}/Downloads
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
