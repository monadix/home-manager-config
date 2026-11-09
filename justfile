# Refresh all automatically managed dependency versions. Review and commit locks.
update:
    nix flake update
    just update-pi-extensions update

# Regenerate the extensions lockfile from extensions/_pins.nix. npm runs in a
# temporary directory against the generated manifest, so no package.json or
# node_modules is written into the checkout. `update-pi-extensions update`
# refreshes floating versions; the default only syncs the lock with the pins.
update-pi-extensions action="install":
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{action}}" in
        install|update) ;;
        *) echo "usage: just update-pi-extensions [install|update]" >&2; exit 2 ;;
    esac
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
