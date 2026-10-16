# Pi: first migration stage

`./default.nix` and `../codex.nix` both use `../AGENTS.md` as their global
instructions. Edit that shared file to update both agents.

Codex remains enabled. Pi uses the native Home Manager module, shared
working preferences, CPA (`gpt-6.1-sol`, medium reasoning), and pinned npm
packages. No vLLM provider is declared or removed. Existing authentication,
sessions, web-search credentials, and extension state stay local. Activation
merges CPA context overrides into writable `models.json`, preserving all other
providers and model metadata (and backing up the original privately).
Defaults match Codex discovery and CLIProxyAPI's model catalog:

| Model | Context tokens |
| --- | ---: |
| `gpt-6.1-sol` | 500,000 |
| `gpt-6-sol` | 272,000 |
| `gpt-5.6-sol` | 272,000 |
| `gpt-5.5` | 272,000 |

These use the standard windows, not optional extended-context maxima.
This is advertised support, not a full-size live proxy request test. Pi's own
compaction policy still reserves room within that window. The override uses
Pi's native metadata layer because the pinned CPA extension restricts its own
overrides to presets that exclude 500,000.

`pi-vim` provides Vim editing. `@fadouse/pi-permission` 0.1.2 replaces the old
permission system and classifier: Bash runs in a native bubblewrap sandbox,
with CPA-backed review for approval requests. Only one permission stack is enabled.

## Activation and ownership

Build with `nix build .#homeConfigurations.MDR024.activationPackage`.
Before activation, move the existing
`~/.pi/agent/pi-cliproxyapi-provider/config.json` to a private backup if Home
Manager reports a collision. Do the same for permission configuration files
if already present. Do not remove authentication or model files.

Activation merges declared settings into writable `settings.json`, preserving
unrelated settings and packages and saving the original as `settings.json.pre-hm`
(mode 0600). Declared defaults and package pins are reapplied on each activation.
Activation also removes retired `@gotgenes/pi-permission-system` and
`pi-permission-classifier` declarations, including old Nix bundle paths, without
deleting their local state. `permissions.json` is HM-managed; project overrides
written by `/permission` take precedence. Malformed runtime JSON and symlinks
are rejected rather than overwritten. Do not activate while Pi is saving its settings.

Extensions are built into the Nix store from `extensions/package-lock.json`
using `importNpmLock`; Pi loads their local package directories without runtime
npm downloads. Host-provided Pi peer libraries are linked from the same Pi runtime,
not installed as separate copies. An offline build check imports them from the
permission extension's location to catch native ESM resolution failures. The bundle
patches the permission reviewer's legacy `completeSimple` import to Pi 1.2's public
`pi-ai/compat` entrypoint.
Activation replaces previous npm declarations and old bundle paths for these
extensions, preserving unrelated packages. `pi update` does not update this bundle.

Run `just update` from the repository to update `flake.lock` and all extension
versions. To update only extensions, run `just update-pi-extensions`. The latter
uses Node from the pinned nixpkgs development shell and refreshes the npm lockfile
without installing packages into the checkout. Dependency integrity hashes come
from the lockfile; no separate Nix hash needs updating. Review the lockfile diff,
build the activation package, and commit the locks before deploying to other hosts.
Updates do not activate or commit automatically; runtime compatibility still
needs validation. Select an available CPA model with `/model` if needed.

## Optional SOPS CPA key

Add an encrypted `pi-cpa-api-key` entry using `sops secrets/secrets.yaml`, then
set this in the relevant host module (or common configuration):

```nix
programs.pi-coding-agent.cpaApiKeySecret = "pi-cpa-api-key";
```

The wrapper reads the decrypted secret at launch into `CLIPROXYAPI_API_KEY`;
only its path enters the Nix store. Missing/empty secrets prevent startup.
The option defaults to null: existing `/login cpa` authentication or an externally
provided `CLIPROXYAPI_API_KEY` remains usable without adding a secret. Do not
put plaintext keys in Nix configuration. The CPA endpoint is a private LAN URL
shared by all hosts; change it here if their network topology differs.

## Context7 and search credentials

Pi's native MCP client connects to Context7 using the existing SOPS
`context7-api-key` secret (also used by OpenCode). The MCP header runs `cat`
on the decrypted secret at connection time; no plaintext key enters the store.
`mcp.json` is HM-managed; change server declarations here rather than with
`pi mcp add`. Check connectivity with `pi mcp list` after activation.

Add an encrypted `exa-api-key` entry using `sops secrets/secrets.yaml`.
The Pi wrapper reads this secret at launch into `EXA_API_KEY`, which takes
precedence over `exaApiKey` in the existing private local
`~/.pi/agent/web-search.json`. Missing/empty secrets prevent startup. The local
file remains untouched, preserving other search settings; its old plaintext
key can be removed after validating the SOPS-backed setup.

## Sandbox and review

Defaults are `workspace-write`, `on-request`, and `auto_review` using
`cpa/codex-auto-review`, independent of the coding model. Low-risk reviews allow
automatically; higher-risk/uncertain reviews and reviewer failures ask you
interactively, or block without a UI. The reviewer sees the operation and local
risk hints, not the conversation. Ordinary sandboxed commands need no review.

Bubblewrap is on Pi's PATH. Bash has a read-only root, writable cwd/temp, and
isolated networking. `/nix/store` is already readable/executable: **do not add
`/nix` to `add_dir`**, which grants writes. The host Nix daemon socket remains
reachable, allowing daemon-mediated builds/downloads despite network isolation.
Client cache writes outside cwd/temp may still need narrow exemptions.

This is Bash isolation, not whole-agent isolation. `write`/`edit` use path checks;
reads and inherited environment are not secret-isolated. The old secret-path
denies are gone. MCP/extension clients and external subagents are not automatically
sandboxed. Project `.pi/permissions.json` can weaken global defaults; inspect it
before trusting a checkout. Keep `.pi/permissions-audit.jsonl` private.

## Validation

Local checks (no provider requests or activation):

```bash
python3 -m unittest discover -s common/agents/pi -p 'test_*.py'
nix build .#homeConfigurations.MDR024.activationPackage
```

After activation, start a **new** Pi session and confirm:

- `/permission` reports `workspace-write/on-request/auto_review` and the CPA reviewer.
- No extension load errors; CPA inference, Vim editing and web tools still work.
- A project write succeeds; an outside write and direct network access are blocked
  unless explicitly approved. Low-risk escalations are reviewed automatically.
- Higher-risk requests and reviewer failure offer a user decision; headless failure
  blocks. Do not approve real destructive operations merely to test the dialog.
- Nix evaluation/build works through the daemon; inspect any requested exemptions.

Local checks do not establish live reviewer or child-agent sandbox behavior.
