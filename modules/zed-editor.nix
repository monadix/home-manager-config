{ 
  pkgs,
  lib,
  config,
  ... 
}: {
  options.zedSettingsTemplate = lib.mkOption {
    type = lib.types.attrs;
    default = {};
  };

  config = {
    programs.zed-editor = {
      enable = true;
      package = let 
        configPath = config.sops.templates."zed-editor-settings.json".path;
      in pkgs.writers.writeNuBin "zeditor" '' 
      def main [ ...args ] {(
        ${lib.getExe pkgs.bubblewrap}
          --bind / / 
          --dev-bind /dev /dev 
          --ro-bind (realpath ${configPath}) (realpath ${configPath})
          --setenv HOME $env.HOME
          --setenv PATH ($env.PATH | str join ':')
          --setenv DISPLAY $env.DISPLAY
          --setenv XDG_RUNTIME_DIR $env.XDG_RUNTIME_DIR
          --chdir $env.PWD 
          ${lib.getExe pkgs.zed-editor} ...$args
      )}'';

      installRemoteServer = true;

      mutableUserDebug = false;
      mutableUserKeymaps = false;
      mutableUserTasks = false;

      extensions = [
        "c3"
        "jq"
        "nix"
        "proto"
        "scheme"
        "terraform"
        "toml"

        "git-firefly"

        "nord"
      ];

      extraPackages = with pkgs; [
        c3-lsp
        nil
        nixd
        rust-analyzer
        terraform-ls
        vscode-langservers-extracted
        package-version-server
        gopls
      ];

      userSettings = {};

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
            "space s" = "vim::HelixSelectRegex";
          };
        }
      ];
    };

    zedSettingsTemplate = {
      cli_default_open_behavior = "new_window";

      theme = "Nord Dark";

      file_scan_exclusions = [];

      terminal.shell.program = "nu";

      vim_mode = true;
      relative_line_numbers = "enabled";

      edit_predictions.mode = "subtle";

      project_panel.dock = "left";
      agent.dock = "right";

      language_models.ollama = {
        api_url = config.sops.placeholder.internal-ollama-url;
        auto_discover = false;
        available_models = [
          {
            name = "gemma4:31b-it-bf16";
            display_name = "gemma 31b";
            max_tokens = 4096;
          }
        ];
      };

      session.trust_all_worktrees = true;

      inlay_hints = {
        enabled = true;
      };

      lsp = {
        rust-analyzer.initialization_options.inlayHints = {
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

    sops.templates."zed-editor-settings.json".content = let 
      extensions = config.programs.zed-editor.extensions;
    in builtins.toJSON (
      config.zedSettingsTemplate 
      // (lib.optionalAttrs (builtins.length extensions > 0) {
        auto_install_extensions = lib.genAttrs extensions (_: true);
      })
    );

    home.file.".config/zed/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."zed-editor-settings.json".path;
    };
  };
}
