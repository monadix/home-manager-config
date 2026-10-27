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
        "@gotgenes/pi-permission-system", "@erichll/pi-auto-review",
        "@fadouse/pi-permission", "pi-permission-classifier",
        "@mzwing/pi-permission-auto-review", "pi-scope-sandbox",
    }
    extras = [source for source in current.get("packages", []) if identity(source) not in names]
    return {**current, **defaults, "packages": packages + extras}


def merge_models(current):
    providers = dict(current.get("providers", {}))
    cpa = dict(providers.get("cpa", {}))
    overrides = dict(cpa.get("modelOverrides", {}))
    # Requested 6.1 budgets; older models keep their standard contexts.
    for model, context in {
        "gpt-6.1-sol": 872000,
        "gpt-6.1-terra": 872000,
        "gpt-6-sol": 272000,
        "gpt-5.6-sol": 272000,
        "gpt-5.5": 272000,
    }.items():
        overrides[model] = {**overrides.get(model, {}), "contextWindow": context}
    cpa["modelOverrides"] = overrides
    providers["cpa"] = cpa
    openai = dict(providers.get("openai", {}))
    overrides = dict(openai.get("modelOverrides", {}))
    overrides["gpt-6.1-sol"] = {**overrides.get("gpt-6.1-sol", {}), "contextWindow": 500000}
    openai["modelOverrides"] = overrides
    providers["openai"] = openai
    # Explicit entries work even when Pi's remote catalog has not caught up.
    for provider, api in (
        ("openai", "openai-responses"),
        ("openai-codex", "openai-codex-responses"),
    ):
        settings = dict(providers.get(provider, {}))
        terra = {
            "id": "gpt-6.1-terra",
            "name": "GPT-6.1 Terra",
            "api": api,
            "reasoning": True,
            "input": ["text", "image"],
            "contextWindow": 272000,
            "maxTokens": 128000,
            "cost": {"input": 1, "output": 5, "cacheRead": 0.05, "cacheWrite": 0},
        }
        models = settings.get("models", [])
        settings["models"] = [
            {**terra, **model} if model["id"] == terra["id"] else model
            for model in models
        ]
        if not any(model["id"] == terra["id"] for model in models):
            settings["models"].append(terra)
        providers[provider] = settings
    codex = dict(providers["openai-codex"])
    overrides = dict(codex.get("modelOverrides", {}))
    for model in ("gpt-6.1-sol", "gpt-6.1-terra"):
        overrides[model] = {**overrides.get(model, {}), "contextWindow": 872000}
    codex["modelOverrides"] = overrides
    providers["openai-codex"] = codex
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
