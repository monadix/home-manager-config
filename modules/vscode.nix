{ pkgs
,
... }:
{
  programs.vscode = rec {
    enable = true;
    package = pkgs.vscode-fhs;

    profiles.default = {

      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;


      userSettings ={
        "editor.lineNumbers" = "relative";
        "extensions.autoCheckUpdates" = false;
        "update.mode" = "none";
        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };
        "git.openRepositoryInParentFolders" = "always";
        "workbench.colorTheme" = "Nord";
        "codeium.enableConfig" = {
          "*" = true;
          "nix" = true;
          "properties" = true;
          "proto" = true;
        };
      };

      extensions = with pkgs.vscode-marketplace; [
        tamasfe.even-better-toml
        golang.go

        haskell.haskell
        justusadam.language-haskell
        ms-vscode.makefile-tools
        bbenoist.nix
        arrterian.nix-env-selector
        arcticicestudio.nord-visual-studio-code
        peterj.proto
        rust-lang.rust-analyzer
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-python.python
        asvetliakov.vscode-neovim
        thenuprojectcontributors.vscode-nushell-lang
        rangav.vscode-thunder-client
      ];
    };
  };
}
