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

          "ctrl-[" = [ 
            "editor::GoToPreviousDiagnostic"
            {
              severity.min = "error"; 
            }
          ];
          "ctrl-]" = [ 
            "editor::GoToDiagnostic"
            {
              severity.min = "error"; 
            }
          ];
        };
      }
      {
        context = "VimControl && showing_code_actions";
        bindings = {
          "k" = "editor::ContextMenuPrevious";
          "j" = "editor::ContextMenuNext";
        };
      }
      {
        context = "vim_mode == visual";
        bindings = {
          "h s" = "vim::HelixSelectRegex";
        };
      }
    ];

    userSettings = {
      theme = "Nord Dark";

      file_scan_exclusions = [];

      terminal.shell.program = "nu";

      vim_mode = true;
      relative_line_numbers = true;

      edit_predictions.mode = "subtle";

      session.trust_all_worktrees = true;

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
