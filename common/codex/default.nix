{ ... }:
{
  programs.codex = {
    enable = true;
    mutableSettings = true;
    context = ./AGENTS.md;

    settings = {
      model = "gpt-6.1-sol";
      model_reasoning_effort = "medium";
      approvals_reviewer = "auto_review";
      approval_policy.granular = {
        sandbox_approval = true;
        rules = true;
        mcp_elicitations = true;
        request_permissions = true;
        skill_approval = true;
      };

      features.daemon_auto_start = true;
      tui.vim_mode_default = true;
    };
  };
}
