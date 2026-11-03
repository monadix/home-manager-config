"""Compare the installed CPA npm resources with the immutable GitHub source."""
import hashlib
import json
from pathlib import Path
import sys

source, installed = map(Path, sys.argv[1:])
package = json.loads((source / "package.json").read_text())
assert not installed.is_symlink(), "CPA must be packed beside its host peers"

expected = {Path("package.json")}
for resource in package["files"]:
    path = source / resource
    if path.is_dir():
        expected.update(p.relative_to(source) for p in path.rglob("*") if p.is_file())
    else:
        assert path.is_file(), resource
        expected.add(Path(resource))
actual = {p.relative_to(installed) for p in installed.rglob("*") if p.is_file()}
assert len(expected) == 24, f"Reviewed CPA resource set changed: {len(expected)} files"
assert actual == expected, f"CPA resource mismatch: missing {expected - actual}, extra {actual - expected}"

digest = hashlib.sha256()
for path in sorted(expected):
    assert not (installed / path).is_symlink(), f"Unexpected CPA symlink: {path}"
    content = (source / path).read_bytes()
    assert (installed / path).read_bytes() == content, f"CPA source bytes changed: {path}"
    digest.update(str(path).encode() + b"\0" + content + b"\0")
print(f"CPA provenance: all 24 packaged resources byte-identical to pinned source; sha256={digest.hexdigest()}")
