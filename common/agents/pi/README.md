# Pi

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

`pi-vim` provides Vim editing. The permission stack is
`@gotgenes/pi-permission-system` 40.2.2, `@mzwing/pi-permission-auto-review`
0.9.1, and [pi-scope-sandbox](https://github.com/monadix/pi-scope-sandbox) pinned
to commit `60d50c7`. The permission system owns policy and prompts, the reviewer
uses session context, and the sandbox confines Bash. The retired fadouse wrapper
and classifier are not loaded alongside them.

## Activation and ownership

Build with `nix build .#homeConfigurations.MDR024.activationPackage`.
Before activation, move the existing
`~/.pi/agent/pi-cliproxyapi-provider/config.json` to a private backup if Home
Manager reports a collision. Do the same for permission configuration files
if already present. Do not remove authentication or model files.

Activation merges declared settings into writable `settings.json`, preserving
unrelated settings and packages and saving the original as `settings.json.pre-hm`
(mode 0600). Declared defaults and package pins are reapplied on each activation.
Activation removes retired `@fadouse/pi-permission` and
`pi-permission-classifier` declarations, including old Nix bundle paths, without
deleting their local state. HM manages the three global files under
`~/.pi/agent/extensions/{pi-permission-system,pi-permission-auto-review,pi-scope-sandbox}/config.json`.
The old HM-owned `permissions.json` link is no longer declared; old project
`.pi/permissions.json` files are not used by this stack. Back up existing files
privately if HM reports ownership collisions; do not delete authentication or
extension state. Malformed runtime settings JSON and symlinks are rejected rather
than overwritten. Do not activate while Pi is saving its settings.

Registry extensions are built into the Nix store from `extensions/package-lock.json`
using `importNpmLock`. The unpublished sandbox is fetched from GitHub with a fixed
revision and content hash in `extensions/_bundle.nix`, then included in the same
bundle. Pi loads local package directories without runtime npm downloads.
Lifecycle scripts are disabled. Host-provided Pi peers are linked from the same
runtime rather than installed as separate copies. Offline build checks exercise
native peer imports, load the real permission/reviewer/sandbox stack in an isolated
SDK session, and verify required-child registration without model calls or Bash
execution. No fadouse compatibility patch remains.
Activation replaces previous npm declarations and old bundle paths for these
extensions, preserving unrelated packages. `pi update` does not update this bundle.

Run `just update` from the repository to update `flake.lock` and all extension
versions. To update only extensions, run `just update-pi-extensions`. The latter
uses Node from the pinned nixpkgs development shell and refreshes the npm lockfile
without installing packages into the checkout. Dependency integrity hashes come
from the lockfile; no separate Nix hash needs updating. Review the lockfile diff,
build the activation package, and commit the locks before deploying to other hosts.
Updates do not activate or commit automatically; runtime compatibility still
needs validation. Security-stack versions are pinned exactly, so upgrading them
requires editing `extensions/package.json` and refreshing its lock. Update the
sandbox's revision/hash in `_bundle.nix` separately after reviewing its changes.
Select an available CPA model with `/model` if needed.

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

Workspace file tools are allowed, with external-directory access requiring
approval. Bash, scope exceptions, and otherwise-unconfigured tools use `ask`.
The `auto-review` authorizer uses `cpa/codex-auto-review` (low reasoning), independent
of the coding model, with bounded active-branch session context. An authorizer may
allow, deny, or defer; review failures defer to the human prompt. A headless request
without an applicable approval fails closed. Path/external-directory boundaries
can still require a human after model review. Unlike the old setup, ordinary Bash
calls also enter the configured permission policy, potentially incurring review.

The sandbox uses absolute Nix Bubblewrap/Bash paths. Bash has a read-only root,
writable workspace, private scratch/HOME, filtered environment and no network by
default. `writeRoot` or `network: true` requests pass through a separate nested
permission gate for that exact call. Network grants enable all host networking,
not just one domain. There is no unsandboxed fallback. `/nix/store` remains readable,
but the host Nix daemon socket is deliberately hidden: daemon-mediated Nix builds
must run from your terminal, not through a blanket exemption.

Sandbox settings are global-only; project files cannot loosen the sandbox. The
permission system still accepts trusted project policy, so inspect that policy
before trusting a checkout. Missing `.pi` directories are created as protected
mountpoints. `!`/`!!` is disabled; use the gated Bash tool or your terminal.

This is Bash confinement, not whole-agent isolation. Native file tools retain
host privileges and depend on path gates; MCP/other trusted extensions are not
OS-contained. General filesystem reads outside explicit masks remain possible.
Native pi-subagents children are required to load the sandbox, permission system
and reviewer even when ambient extensions are excluded. Unsupported external
runner/machine routes are rejected. This does not establish whole-process child
confinement or end-to-end workflow compatibility.

## Validation

Local checks (no provider requests or activation):

```bash
python3 -m unittest discover -s common/agents/pi -p 'test_*.py'
nix build .#homeConfigurations.MDR024.activationPackage
```

After activation, start a **new** Pi session and confirm:

- `/scope-sandbox` reports workspace-write mode, networking disabled, and the pinned binaries load.
- `/permission-auto-review show` reports `cpa/codex-auto-review`.
- No extension load errors; CPA inference, Vim editing and web tools still work.
- Workspace writes succeed; external writes and network scopes follow the expected
  contextual review/human approval path. A later call does not inherit a scope grant.
- Denial and reviewer failure do not execute an unapproved operation. Do not approve
  real destructive operations merely to test the dialog.
- Native child launches retain the required extensions; external runners are blocked.
- Nix daemon access from sandboxed Bash fails rather than retrying outside isolation.

Local checks do not establish live reviewer or child-agent sandbox behavior.
