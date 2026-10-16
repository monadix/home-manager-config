# Pi: first migration stage

`./default.nix` and `../codex.nix` both use `../AGENTS.md` as their global
instructions. Edit that shared file to update both agents.

Codex remains enabled. Pi 1.0.3 uses the native Home Manager module, shared
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

`pi-vim` is the most adopted of the evaluated Vim editors.
`@gotgenes/pi-permission-system` has substantially more adoption than the
other evaluated approval gates. `pi-permission-classifier` adds automatic
allow/deny/defer review; the first-party model judge is deny-focused instead.
These choices are based on npm downloads and repository activity, not a
security audit. Only one editor replacement is enabled.

## Activation and ownership

Build with `nix build .#homeConfigurations.MDR024.activationPackage`.
Before activation, move the existing
`~/.pi/agent/pi-cliproxyapi-provider/config.json` to a private backup if Home
Manager reports a collision. Do the same for permission configuration files
if already present. Do not remove authentication or model files.

Activation merges declared settings into writable `settings.json`, preserving
unrelated settings and packages and saving the original as `settings.json.pre-hm`
(mode 0600). Declared defaults and package pins are reapplied on each activation.
The classifier configuration stays writable, but activation reapplies
`cpa/codex-auto-review` as the default. A small patch in the pinned extension
bundle routes that default to `openai/codex-auto-review` while the coding
provider is `openai`, and back to CPA for every other provider. Routing follows
model switches; a missing reviewer or authentication still defers to you, not
to another provider. Explicit `--permission-model` overrides retain precedence.
Other `/permission-model` selections persist until activation reapplies the default.
Activation also registers the direct reviewer in writable `models.json`, since
Pi's public catalog omits it. Malformed JSON and symlinks are rejected rather
than overwritten. Do not activate while Pi is saving its settings.

Extensions are built into the Nix store from `extensions/package-lock.json`
using `importNpmLock`; Pi loads their local package directories without runtime
npm downloads. Host-provided Pi peer libraries are not installed into the bundle.
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

## Validation before retiring Codex

After activation, start a **new** Pi session and confirm:

- No extension load errors; `/model` lists CPA models and a prompt succeeds.
- Vim Insert/Normal/Visual editing works; `/settings` changes persist.
- `/permission-system show` lists the classifier chain; the footer shows
  `judge:openai/codex-auto-review` for an `openai` coding model and
  `judge:cpa/codex-auto-review` otherwise, including after model switches.
  Both reviewers need their own provider's authentication.
- A benign bash request is automatically approved; dangerous/uncertain requests
  are denied or prompt. Reviewer timeout/auth failure must fall back to prompting
  (or blocking without UI), never silently allow.
- Web tools and other extension tools pass through the permission gate.
  Exercise subagents only when explicitly requested. This permission system
  documents native child forwarding for `@gotgenes/pi-subagents`, **not** the
  separately published `pi-subagents`; child coverage is not yet verified.

In-tree file reads/writes are allowed; bash and unknown tool surfaces are reviewed.
Outside-directory access prompts rather than being classified. Sensitive paths
are denied by deterministic rules. Review logs can contain tool payloads:
handle them privately. This is an approval workflow, **not an OS sandbox**;
processes and child agents may not inherit the gate. Do not retire Codex until
these interactive and headless behavior checks pass.
