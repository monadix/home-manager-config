"""Apply HM defaults without making Pi's runtime settings read-only."""

import json
import os
from pathlib import Path
import sys
import tempfile


def merge_settings(current, defaults):
    packages = defaults["packages"]
    names = {source.rsplit("@", 1)[0] for source in packages}
    extras = [
        source for source in current.get("packages", [])
        if not isinstance(source, str)
        or (source not in names and source.rsplit("@", 1)[0] not in names)
    ]
    return {**current, **defaults, "packages": packages + extras}


def main():
    directory = Path(sys.argv[1])
    directory.mkdir(parents=True, exist_ok=True)
    defaults = json.loads(Path(sys.argv[2]).read_text())
    for name, values in (
        ("settings.json", defaults),
        ("extensions/pi-permission-classifier/config.json", {"timeoutMs": 30000}),
    ):
        path = directory / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.is_symlink():
            raise RuntimeError(f"Refusing to replace symlink: {path}")
        current = json.loads(path.read_text()) if path.exists() else {}
        merged = merge_settings(current, values) if name == "settings.json" else {**values, **current}
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
