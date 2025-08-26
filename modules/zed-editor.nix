{ 
  pkgs,
  ... 
}:
{
  programs.zed-editor = {
    enable = true;
    installRemoteServer = true;

    extensions = [
      "c3"
      "git-firefly"
      "nix"
      "nord"
      "toml"
      "scheme"
    ];

    extraPackages = with pkgs; [
      c3-lsp
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
      {
        context = "VimControl && showing_code_actions";
        bindings = {
          "k" = "editor::ContextMenuPrevious";
          "j" = "editor::ContextMenuNext";
        };
      }
    ];

    userSettings = {
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
