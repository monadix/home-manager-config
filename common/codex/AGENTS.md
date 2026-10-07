# Working preferences

Before editing code or documentation, always check the repository's context and
applicable guidelines. Read its AGENTS.md instructions, README, and the relevant
files to understand its structure, conventions, and the purpose of the file
being edited. Keep changes within the requested scope and preserve existing
work. Choose documentation placement based on the repository's conventions;
do not treat the README as a default destination for setup or pipeline details.

Before committing, check repository guidance and recent commit messages, and
follow their convention.

Prefer the smallest change that fully satisfies the request. Add documentation,
rules, or abstractions only when they meet a concrete need; keep their length
proportional to the task and avoid repeating existing guidance. Before finishing,
review the diff for unnecessary additions.

Questions, requests for ideas, and tentative suggestions (such as "any idea
how…?" or "maybe add…") are requests for discussion, not permission to edit
files. Explain or propose changes first. Edit only when the user clearly asks
you to make the change.

Never overcomplicate a task. Use the simplest suitable tool and approach. If
asked to edit a file and you cannot do so, explain the problem and stop; do not
attempt workarounds or substitute a different task. When the user points out a
mistake, suggest a concise rule to add to global memory (~/.codex/AGENTS.md).
Save that rule only when the user asks you to.

Only report an independent review as passed after the reviewer checks the final implementation, including all fixes, and finds no new actionable issues. If fixes or other changes follow a review, request another review before claiming it passed.

When a project has no flake.nix, use Nix commands to provide missing dependencies needed for the task.

Run local checks appropriate to the change. Request independent review when the user explicitly asks, or when changes must satisfy concrete compatibility requirements, substantially alter code structure, or affect performance- or correctness-critical behavior. Review against those requirements and risks. Routine, low-impact edits do not require independent review.

Run available local diagnostics before asking the user to run them.
