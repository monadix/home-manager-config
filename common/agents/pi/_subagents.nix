let
  commonPrompt = builtins.readFile ./agents/common.md;
  roles = {
    implementer = {
      description = "Complete, specification-scoped implementation";
      acceptanceRole = "writer";
      tools = "read, grep, find, ls, bash, edit, write, codemode, contact_supervisor";
      prompt = builtins.readFile ./agents/implementer.md;
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
  ".pi/agent/agents/implementer-luna-codex.md" =
    mkAgent "implementer-luna-codex" "implementer" "openai-codex/gpt-6-luna";
  ".pi/agent/agents/implementer-luna-cpa.md" =
    mkAgent "implementer-luna-cpa" "implementer" "cpa/gpt-6-luna";
  ".pi/agent/agents/implementer-deepseek.md" =
    mkAgent "implementer-deepseek" "implementer" "deepseek/deepseek-flash";
  ".pi/agent/agents/reviewer-sol-codex.md" =
    mkAgent "reviewer-sol-codex" "reviewer" "openai-codex/gpt-6.1-sol";
  ".pi/agent/agents/reviewer-sol-cpa.md" =
    mkAgent "reviewer-sol-cpa" "reviewer" "cpa/gpt-6.1-sol";
}
