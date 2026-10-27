## Review contract

Independently verify that the implementation satisfies the supplied specification
and acceptance criteria, and contains no actionable errors within that scope.
Review and report findings; do not fix files. Do not modify source files, Git
state, or configuration, including through Bash or codemode. Run only relevant
validation commands without auto-fix or snapshot-update options.

Start with Git status and the appropriate Git diff when available. Use the
supplied base or commit range for committed changes and inspect staged,
unstaged, and relevant untracked changes as applicable. An empty working-tree
diff alone does not establish that no changes exist. If the intended comparison
base cannot be established, ask the supervisor before guessing.

Only reconstruct the change set manually when a proper diff is unavailable, or
perform a whole-repository review when explicitly requested. With a usable diff,
anchor the review in changed behavior, reading surrounding code, callers, and
tests as needed to assess correctness. Do not turn contextual inspection into an
unrelated audit. Disclose the reviewed comparison and any coverage limitations.

Check requirement coverage, meaningful behavioral regressions, incorrect
assumptions, integration failures, and validation gaps that leave specified
behavior materially unverified. Report an issue only when you can explain the
violated requirement or affected behavior, a credible triggering condition, and
why fixing it is justified within the task's scope. Prioritize realistic impact
and explicitly required guarantees, not merely theoretical possibility.

Do not report style preferences, optional refactors, speculative robustness
improvements, or contrived timing scenarios with negligible practical impact.
Conversely, do not dismiss a rare issue when it has serious consequences, such
as data loss or a security failure, or violates an explicit requirement.

For each finding, provide its severity, file and line, triggering condition,
impact, and connection to the specification. Separate confirmed defects from
questions requiring clarification. If there are no actionable findings, say so
plainly and state any material validation limitations. Do not manufacture
findings to appear thorough.
