"""Apply HM defaults without making Pi's runtime settings read-only."""

import json
import os
from pathlib import Path
import sys
import tempfile


def merge_settings(current, defaults):
    packages = defaults["packages"]
    def identity(source):
        if isinstance(source, dict):
            source = source.get("source", "")
        if "/lib/pi-extensions/node_modules/" in source:
            return source.split("/lib/pi-extensions/node_modules/", 1)[1]
        if source.startswith("npm:"):
            name = source[4:]
            return name.rsplit("@", 1)[0] if "@" in name[1:] else name
        return source

    names = {identity(source) for source in packages} | {
        "@gotgenes/pi-permission-system", "pi-permission-classifier",
    }
    extras = [source for source in current.get("packages", []) if identity(source) not in names]
    return {**current, **defaults, "packages": packages + extras}


def merge_models(current):
    providers = dict(current.get("providers", {}))
    cpa = dict(providers.get("cpa", {}))
    overrides = dict(cpa.get("modelOverrides", {}))
    # Standard contexts advertised by Codex and CLIProxyAPI's model catalog.
    for model, context in {
        "gpt-6.1-sol": 500000,
        "gpt-6-sol": 272000,
        "gpt-5.6-sol": 272000,
        "gpt-5.5": 272000,
    }.items():
        overrides[model] = {**overrides.get(model, {}), "contextWindow": context}
    cpa["modelOverrides"] = overrides
    providers["cpa"] = cpa
    return {**current, "providers": providers}


def main():
    directory = Path(sys.argv[1])
    directory.mkdir(parents=True, exist_ok=True)
    defaults = json.loads(Path(sys.argv[2]).read_text())
    for name, values in (
        ("settings.json", defaults),
        ("models.json", {}),
    ):
        path = directory / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.is_symlink():
            raise RuntimeError(f"Refusing to replace symlink: {path}")
        current = json.loads(path.read_text()) if path.exists() else {}
        if name == "settings.json":
            merged = merge_settings(current, values)
        else:
            merged = merge_models(current)
        if merged == current:
            continue
        if path.exists():
            backup = path.with_name(path.name + ".pre-hm")
            if not backup.exists():
                with open(backup, "x", opener=lambda p, flags: os.open(p, flags, 0o600)) as file:
                    file.write(path.read_text())
        fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
        try:
            with os.fdopen(fd, "w") as file:
                json.dump(merged, file, indent=2)
                file.write("\n")
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)


if __name__ == "__main__":
    main()
