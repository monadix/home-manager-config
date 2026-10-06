# Luakit configuration

`default.nix` manages `~/.config/luakit/userconf.lua` and `theme.lua`.
Keep permanent settings and startup imports in the HM-generated `userconf.lua`.

Use this layout for additional Lua files:

```text
~/.config/luakit/
├── userconf.lua             # HM-managed settings and imports
├── theme.lua                # HM-managed theme
├── modules/                 # Permanent modules managed by HM
│   ├── bindings.lua         # UI process
│   └── custom_filter_wm.lua # WebProcess
└── tmp/                     # Local experiments, outside HM
    ├── experiment.lua       # UI process
    └── request_trace_wm.lua # WebProcess
```

These directories are a local convention; Luakit does not load their contents
automatically. Use underscores in module filenames and the bundled `_wm.lua`
suffix for WebProcess modules. The loader, not the suffix, selects the process.
UI scripts handle settings, bindings, windows and tabs; WebProcess modules handle
page DOM and request interception.

For permanent modules, keep sources under this module's `modules/` directory and
register individual files in `default.nix`, for example:

```nix
xdg.configFile."luakit/modules/bindings.lua".source = ./modules/bindings.lua;
```

Import them explicitly in the generated `userconf.lua`:

```lua
require("modules.bindings")
require_web_module("modules.custom_filter_wm")
```

Load experiments manually from Luakit's command bar:

```text
:lua dofile(luakit.config_dir .. "/tmp/experiment.lua")
:lua require_web_module("tmp.request_trace_wm")
```

Manual loading lasts for the running browser process unless the script explicitly
writes persistent state. Files in `tmp/` remain on disk across restarts and are
not loaded at startup. `dofile` executes on every call; module loading through
`require` is cached, and `require_web_module` also deduplicates module names.
Restart to reload an edited WebProcess module. For tracing that attaches through
`page-created`, open a new tab after loading it.

Keep WebProcess module files inside Luakit's configuration directory so the
patched sandbox can read them. Copy experiments from elsewhere rather than
symlinking to a location outside the sandbox's allowed paths.
