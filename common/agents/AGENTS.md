# Working preferences

Global Codex and Pi instructions are managed by Home Manager from one shared
file. Edit `home-manager/common/agents/AGENTS.md` in the configuration repository,
never `~/.codex/AGENTS.md` or `~/.pi/agent/AGENTS.md` directly.

Before editing code or documentation, always check the repository's context and
applicable guidelines. Read its AGENTS.md instructions, README, and the relevant
files to understand its structure, conventions, and the purpose of the file
being edited. Keep changes within the requested scope and preserve existing
work. Choose documentation placement based on the repository's conventions;
do not treat the README as a default destination for setup or pipeline details.
Follow referenced guidelines relevant to the change; existing files may reflect
outdated conventions.

Before committing, check repository guidance and recent commit messages, and
follow their convention.

For Git operations, use the configured SSH agent and askpass flow. Askpass
prompts are expected, and the user should approve SSH operations manually when
prompted. Do not force `BatchMode`, suppress authentication prompts, or switch
to HTTPS tokens as an authentication workaround unless explicitly requested.

Prefer the smallest change that fully satisfies the request. Add documentation,
rules, or abstractions only when they meet a concrete need; avoid repeating
existing guidance. Keep feature documentation proportional to the feature's
scope. Before finishing, review the diff for unnecessary additions.

Document durable repository-specific information, not a narration of the change
or behavior already clear from nearby configuration.

Prefer existing tools and declarative configuration over custom scripts. Add
scripting only where those cannot express the required behavior, and keep it
minimal.

Questions, requests for ideas, and tentative suggestions (such as "any idea
how…?" or "maybe add…") are requests for discussion, not permission to edit
files. Explain or propose changes first. Edit only when the user clearly asks
you to make the change.

Do not treat “continue” or similar follow-ups as authorization to implement a
proposal. Present the proposal first, then wait for explicit implementation
approval before editing files.

Never overcomplicate a task. Use the simplest suitable tool and approach. If
asked to edit a file and you cannot do so, explain the problem and stop; do not
attempt workarounds or substitute a different task. When the user points out a
mistake, suggest a concise rule to add to global memory in the Home Manager source.
Save that rule only when the user asks you to.

When proposing a memory rule after a correction, describe a reusable behavior
rather than the project’s terminology, features, or implementation details.

Bound delegated stages with explicit handoff conditions and early checkpoints.
A checkpoint may report unfinished work; it is not a claim of completion.
When a delegated session approaches its context limit or repeatedly uses stale
state, checkpoint it and hand off a narrowly scoped task to a fresh session instead
of repeatedly resuming it.

Only report an independent review as passed after the reviewer checks the final implementation, including all fixes, and finds no new actionable issues. If fixes or other changes follow a review, request another review before claiming it passed.

When a project has no flake.nix, use Nix commands to provide missing dependencies needed for the task.

Run local checks appropriate to the change. Request independent review when the user explicitly asks, or when changes must satisfy concrete compatibility requirements, substantially alter code structure, or affect performance- or correctness-critical behavior. Review against those requirements and risks. Routine, low-impact edits do not require independent review.

For changes based on an approved visual reference, compare every affected screen in the running application against that reference before reporting completion; functional checks alone do not establish visual fidelity.

Run available local diagnostics before asking the user to run them.

Use `run0` rather than `sudo` for privileged commands on this system.
