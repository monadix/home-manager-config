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

`pi-vim` provides Vim editing. Pi's native tools run with the user's normal
account privileges; HM does not install a generic permission/reviewer stack or
confine Bash. No `yoloMode` switch is needed with that stack removed.
Independent extensions may still show their own dialogs or require login.

## Automatic retries

Transient model failures use Pi's native exponential backoff: up to 20 retries,
waiting 5, 10, 20, 40, then 60 seconds between attempts (capped at 60 seconds).
This allows roughly 17 minutes of backoff, plus request time, before giving up.
Permanent errors are not made retryable; provider-level retries stay at Pi's
native default of zero.

## Activation and ownership

Build with `nix build .#homeConfigurations.MDR024.activationPackage`.
Before activation, move the existing
`~/.pi/agent/pi-cliproxyapi-provider/config.json` to a private backup if Home
Manager reports a collision. Do not remove authentication, model files, or local
extension state.

Activation merges declared defaults into writable `settings.json`, preserving
unrelated settings and packages and saving the original as `settings.json.pre-hm`
(mode 0600). Retired permission/reviewer and sandbox package declarations,
including old Nix bundle paths, are removed during activation without deleting
local extension state. Any old HM-managed permission/reviewer/sandbox config
links are no longer declared. Malformed runtime settings JSON and symlinks are
rejected rather than overwritten. Do not activate while Pi is saving settings.

Registry extensions are built into the Nix store from `extensions/package-lock.json`
using `importNpmLock`; lifecycle scripts are disabled. Host-provided Pi peers are
linked from the same runtime rather than installed as separate copies. Offline
build checks verify native peer imports without provider calls.
Activation replaces previous npm declarations and old bundle paths for these
extensions, preserving unrelated packages. `pi update` does not update this bundle.

Run `just update` from the repository to update `flake.lock` and extension
versions. To update only extensions, run `just update-pi-extensions`. The latter
uses Node from the pinned nixpkgs development shell and refreshes the npm lockfile
without installing packages into the checkout. Select an available CPA model
with `/model` if needed.

## SOPS CPA key

All hosts use the encrypted `pi-cpa-api-key` entry in `secrets/secrets.yaml`,
selected by `programs.pi-coding-agent.cpaApiKeySecret` in the common configuration.
The wrapper reads the decrypted secret at launch into `CLIPROXYAPI_API_KEY`;
only its path enters the Nix store. Missing/empty secrets prevent startup.
A saved `/login cpa` key takes precedence during model discovery; clear stale
saved credentials if refresh still returns 401 after activation and restarting Pi.
The CPA endpoint is stored as `internal-cpa-url` in the same SOPS file and shared
by all hosts. SOPS renders the provider config at runtime; Home Manager links to
that file so the endpoint does not enter the Nix store. Update the endpoint with
`sops secrets/secrets.yaml`. Do not put plaintext keys or internal URLs in Nix
configuration.

## SOPS DeepSeek key

Add an encrypted `deepseek-api-key` entry using `sops secrets/secrets.yaml`
before activation. The Pi wrapper reads this secret at launch into
`DEEPSEEK_API_KEY`; only its path enters the Nix store. Missing/empty secrets
prevent startup. Restart Pi after activation and select DeepSeek with `/model`.
A saved DeepSeek credential in `auth.json` takes precedence; use `/logout`
for DeepSeek to remove it if you want to use the SOPS-backed key.
The default provider remains CPA.

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

## Native tool access

Pi uses its native tool behavior with ordinary user-account access. No HM-managed
generic reviewer, permission gate, or Bash sandbox is configured. Per-extension
interactions (for example, login or extension-specific dialogs) may still apply.
This describes configuration after activation; already-running sessions do not
change, and local extension state/files are not deleted by activation.

## Validation

Local checks (no provider requests or activation):

```bash
python3 -m unittest discover -s common/agents/pi -p 'test_*.py'
nix build .#homeConfigurations.MDR024.activationPackage
```

After activation, start a **new** Pi session and confirm no generic permission,
reviewer, or sandbox extensions load; Vim and the configured provider/web tools
remain available. This does not test live model requests or independent extension
dialogs.
