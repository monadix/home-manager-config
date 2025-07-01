{ 
  pkgs,
  ... 
}:
{
  programs.zed-editor = {
    enable = true;
    installRemoteServer = true;

    extensions = [
      "git-firefly"
      "nix"
      "nord"
      "toml"
    ];

    extraPackages = with pkgs; [
      nil
      nixd
      rust-analyzer
      vscode-langservers-extracted
      package-version-server
      gopls
    ];

    userKeymaps = [
      {
        context = "VimControl && !menu";
        bindings = {
          "space f" = "file_finder::Toggle";
          "ctrl-b" = "workspace::ToggleLeftDock";
          "ctrl-j" = "workspace::ToggleBottomDock";
        };
      }
    ];

    userSettings = {
      ui_font_size = 16;
      buffer_font_size = 16;

      theme = "Nord";

      file_scan_exclusions = [];

      vim_mode = true;
      relative_line_numbers = true;

      edit_predictions.mode = "subtle";

      inlay_hints = {
        enabled = true;
      };

      lsp = {
        rust_analyzer.initialization_options.inlayHints = {
          maxLength = null;        
          lifetimeEllistionHints = {
            enable = "skip_trivial";
            useParameterNames = true;
          };
          closureReturnTypeHints = {
            enable = "always";
          };
        };
      };
    };
  };
}
