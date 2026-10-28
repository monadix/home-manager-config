let
  commonPrompt = builtins.readFile ./agents/common.md;
  roles = rec {
    implementer = {
      description = "Complete, specification-scoped implementation";
      acceptanceRole = "writer";
      tools = "read, grep, find, ls, bash, edit, write, codemode, contact_supervisor";
      prompt = builtins.readFile ./agents/implementer.md;
    };
    implementer-fast = implementer // {
      description = "Complete, specification-scoped implementation for well-scoped changes with a clear approach";
    };
    implementer-hard = implementer // {
      description = "Complete, specification-scoped implementation for difficult debugging, ambiguous interactions, or correctness-sensitive changes";
    };
    reviewer = {
      description = "Diff-first, specification-scoped review without fixes";
      acceptanceRole = "read-only";
      tools = "read, grep, find, ls, bash, codemode, contact_supervisor";
      prompt = builtins.readFile ./agents/reviewer.md;
    };
  };
  mkAgent = name: roleName: model:
    let
      role = roles.${roleName};
    in {
      text = ''
        ---
        name: ${name}
        description: ${role.description} (${model})
        model: ${model}
        tools: ${role.tools}
        acceptanceRole: ${role.acceptanceRole}
        advertise: true
        systemPromptMode: append
        inheritProjectContext: true
        inheritGlobalContext: true
        inheritSkills: false
        defaultContext: fresh
        thinking: high
        ---

      '' + commonPrompt + "\n" + role.prompt;
    };
in
{
  ".pi/agent/agents/implementer-fast-codex.md" =
    mkAgent "implementer-fast-codex" "implementer-fast" "openai-codex/gpt-6-luna";
  ".pi/agent/agents/implementer-hard-codex.md" =
    mkAgent "implementer-hard-codex" "implementer-hard" "openai-codex/gpt-6.1-terra";
  ".pi/agent/agents/implementer-fast-cpa.md" =
    mkAgent "implementer-fast-cpa" "implementer-fast" "cpa/gpt-6-luna";
  ".pi/agent/agents/implementer-hard-cpa.md" =
    mkAgent "implementer-hard-cpa" "implementer-hard" "cpa/gpt-6.1-terra";
  ".pi/agent/agents/implementer-deepseek.md" =
    mkAgent "implementer-deepseek" "implementer" "deepseek/deepseek-flash";
  ".pi/agent/agents/reviewer-sol-codex.md" =
    mkAgent "reviewer-sol-codex" "reviewer" "openai-codex/gpt-6.1-sol";
  ".pi/agent/agents/reviewer-sol-cpa.md" =
    mkAgent "reviewer-sol-cpa" "reviewer" "cpa/gpt-6.1-sol";
}
