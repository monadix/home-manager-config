# Refresh all automatically managed dependency versions. Review and commit locks.
update:
    nix flake update
    just update-pi-extensions

# Sync the extensions lockfile with extensions/_pins.nix.
lock-pi-extensions: (_lock-pi-extensions "install")

# Refresh the extensions lockfile, including floating versions.
update-pi-extensions: (_lock-pi-extensions "update")

# Run npm in a temporary directory against the generated manifest, so no
# package.json or node_modules is written into the checkout.
_lock-pi-extensions action:
    #!/usr/bin/env bash
    set -euo pipefail
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    cp "$(nix build --no-link --print-out-paths .#pi-extensions-manifest)/package.json" "$work/"
    if test -f common/agents/pi/extensions/package-lock.json; then
        cp common/agents/pi/extensions/package-lock.json "$work/"
    fi
    WORK="$work" ACTION="{{action}}" nix develop .#pi-extensions --command bash -c '
        cd "$WORK"
        npm "$ACTION" --package-lock-only --ignore-scripts --legacy-peer-deps --no-audit
    '
    cp "$work/package-lock.json" common/agents/pi/extensions/package-lock.json
