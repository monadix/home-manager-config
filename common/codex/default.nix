{
  programs.codex = {
    enable = true;
    context = ./AGENTS.md;

    settings = {
      model = "gpt-6.1-sol";
      model_reasoning_effort = "medium";
      approvals_reviewer = "auto_review";

      projects = {
        "/home/monadix/FH/config/home-manager".trust_level = "trusted";
        "/home/monadix/FH/config/nixos".trust_level = "trusted";
        "/home/monadix/FH/config".trust_level = "trusted";
        "/home/monadix/FH/xxx/os/dckr".trust_level = "trusted";
        "/home/monadix/FH/external/luakit".trust_level = "trusted";
        "/home/monadix".trust_level = "trusted";
      };

      tui.vim_mode_default = true;
    };
  };
}
