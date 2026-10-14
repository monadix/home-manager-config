# Pi: first migration stage

Codex remains enabled. Pi 1.0.3 uses the native Home Manager module, shared
working preferences, CPA (`gpt-6.1-sol`, medium reasoning), and pinned npm
packages. No vLLM provider is declared or removed; existing `models.json`,
authentication, sessions, web-search credentials, and extension state stay local.

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
The classifier configuration is seeded as writable, so `/permission-model`
can persist a reviewer selection. Malformed JSON and symlinks are rejected
rather than overwritten. Do not activate while Pi is saving its settings.

Pi resolves/downloads the pinned npm packages on startup; these are not
Nix-packaged or vendored. Select an available CPA model with `/model` if the
configured default is unavailable. CPA availability was checked against the
local discovery cache, not a live authenticated request.

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

## Validation before retiring Codex

After activation, start a **new** Pi session and confirm:

- No extension load errors; `/model` lists CPA models and a prompt succeeds.
- Vim Insert/Normal/Visual editing works; `/settings` changes persist.
- `/permission-system show` lists the classifier chain; the footer shows
  `judge:session`. `/permission-model` can choose a separate authenticated,
  tool-calling reviewer without changing the session model.
- A benign bash request is automatically approved; dangerous/uncertain requests
  are denied or prompt. Reviewer timeout/auth failure must fall back to prompting
  (or blocking without UI), never silently allow.
- Web tools and other extension tools pass through the permission gate.
  Exercise subagents only when explicitly requested. This permission system
  documents native child forwarding for `@gotgenes/pi-subagents`, **not** the
  existing `pi-subagents@0.70.0`; child coverage is not yet verified.

In-tree file reads/writes are allowed; bash and unknown tool surfaces are reviewed.
Outside-directory access prompts rather than being classified. Sensitive paths
are denied by deterministic rules. Review logs can contain tool payloads:
handle them privately. This is an approval workflow, **not an OS sandbox**;
processes and child agents may not inherit the gate. Do not retire Codex until
these interactive and headless behavior checks pass.
