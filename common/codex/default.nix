{ lib, pkgs, ... }:
let
  launcher = pkgs.writeTextFile {
    name = "codex-launcher";
    destination = "/bin/codex";
    executable = true;
    text = "#!${lib.getExe pkgs.nushell} --no-config-file\n"
      + builtins.replaceStrings [ "@codex@" ] [ (lib.getExe pkgs.codex) ]
        (builtins.readFile ./wrapper.nu);
  };
in
{
  programs.codex = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "codex-${pkgs.codex.version}";
      inherit (pkgs.codex) version meta;
      paths = [ pkgs.codex ];
      postBuild = ''
        ln -sf ${launcher}/bin/codex "$out/bin/codex"
      '';
    };
    context = ./AGENTS.md;

    profiles.hm = {
      model = "gpt-6.1-sol";
      model_reasoning_effort = "medium";
      approvals_reviewer = "auto_review";

      tui.vim_mode_default = true;
    };
  };
}
