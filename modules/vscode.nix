{ vscode-extensions
,
... }:
{
  programs.vscode = rec {
    enable = true;
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
    };

    extensions = with vscode-extensions.vscode-marketplace; [
      tamasfe.even-better-toml
      golang.go
      haskell.haskell
      justusadam.language-haskell
      bbenoist.nix
      arrterian.nix-env-selector
      arcticicestudio.nord-visual-studio-code
      rust-lang.rust-analyzer
      ms-vscode-remote.remote-containers
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-python.python
      asvetliakov.vscode-neovim
    ];
  };
}
