{ pkgs, webkit-dev, ... }:
let
  luakit = (pkgs.luakit.override {
    webkitgtk_4_1 = webkit-dev.packages.${pkgs.stdenv.hostPlatform.system}.validation;
  }).overrideAttrs (oldAttrs: {
    src = pkgs.fetchFromGitHub {
      owner = "monadix";
      repo = "luakit";
      # sandbox-webprocess-broker
      rev = "39232d48c4e167d1c9612def71a983e2e2bbe3db";
      hash = "sha256-wI+DxNyoJXfnQZIAF7rCbWrSsvc2Y6zkj6glCqjcSUY=";
    };
    preFixup = (oldAttrs.preFixup or "") + ''
      gappsWrapperArgs+=(
        --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${pkgs.pipewire}/lib/gstreamer-1.0"
      )
    '';
  });
in
{
  home.packages = [ luakit ];

  home.sessionVariables.WEBKIT_A11Y_BUS_ADDRESS = "";

  xdg.configFile."luakit/userconf.lua".text = ''
    require("settings").application.prefer_dark_mode = true
    require("settings").webview.enable_media_stream = true
    require("modules.session_autosave")
    require("modules.media_permissions")
  '';

  xdg.configFile."luakit/modules/session_autosave.lua".source = ./modules/session_autosave.lua;
  xdg.configFile."luakit/modules/media_permissions.lua".source = ./modules/media_permissions.lua;

  xdg.configFile."luakit/theme.lua".text = ''
    local theme = dofile("${luakit}/etc/xdg/luakit/theme.lua")

    theme.fg = "#eceff4"
    theme.bg = "#2e3440"
    theme.success_fg = "#a3be8c"
    theme.loaded_fg = "#88c0d0"
    theme.error_fg = "#eceff4"
    theme.error_bg = "#bf616a"
    theme.warning_fg = "#2e3440"
    theme.warning_bg = "#ebcb8b"
    theme.notif_fg = theme.fg
    theme.notif_bg = "#3b4252"
    theme.menu_fg = theme.fg
    theme.menu_bg = "#3b4252"
    theme.menu_selected_fg = theme.fg
    theme.menu_selected_bg = "#4c566a"
    theme.menu_title_bg = theme.bg
    theme.menu_primary_title_fg = "#88c0d0"
    theme.menu_secondary_title_fg = "#d8dee9"
    theme.sbar_fg = theme.fg
    theme.sbar_bg = theme.bg
    theme.dbar_fg = theme.fg
    theme.dbar_bg = theme.bg
    theme.dbar_error_fg = "#bf616a"
    theme.ibar_fg = theme.fg
    theme.tab_fg = "#d8dee9"
    theme.tab_bg = "#3b4252"
    theme.tab_hover_bg = "#434c5e"
    theme.selected_fg = theme.fg
    theme.selected_bg = theme.bg
    theme.loading_fg = "#88c0d0"
    theme.loading_bg = theme.bg
    theme.trust_fg = "#a3be8c"
    theme.notrust_fg = "#bf616a"
    theme.hint_fg = theme.bg
    theme.hint_bg = "#ebcb8b"
    theme.hint_border = "1px solid #4c566a"
    theme.ok = { fg = theme.fg, bg = theme.bg }
    theme.warn = { fg = theme.warning_fg, bg = theme.warning_bg }
    theme.error = { fg = theme.error_fg, bg = theme.error_bg }

    return theme
  '';
}
