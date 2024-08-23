{ pkgs
, vscode-extensions
,
... }:
{
  programs.vscode = rec {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;

    package = pkgs.vscode-fhs;

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
      };
    };

    extensions = with vscode-extensions.vscode-marketplace; [
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
    ];
  };
}
