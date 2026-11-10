{ pkgsMaster, ... }:
{
  programs.codex = {
    enable = true;
    # Temporary until nixos-unstable includes the Codex build fix (nixpkgs#584667).
    package = pkgsMaster.codex;
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

      tui.vim_mode_default = true;
    };
  };
}
