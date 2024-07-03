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
      "workbench.colorTheme" = "Kimbie Dark";
    };

    extensions = with vscode-extensions.vscode-marketplace; [
      tamasfe.even-better-toml
      golang.go
      haskell.haskell
      justusadam.language-haskell
      bbenoist.nix
      arrterian.nix-env-selector
      rust-lang.rust-analyzer
      ms-python.python
      asvetliakov.vscode-neovim
    ];
  };
}
