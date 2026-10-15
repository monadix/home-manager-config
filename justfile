# Refresh all automatically managed dependency versions. Review and commit locks.
update:
    nix flake update
    just update-pi-extensions

# Use npm from this repository's pinned nixpkgs, not the ambient PATH.
update-pi-extensions:
    nix develop .#pi-extensions --command npm update --prefix common/agents/pi/extensions --package-lock-only --ignore-scripts --legacy-peer-deps
