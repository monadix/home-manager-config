# Home Manager configuration

This repository describes monadix's user environment for each logical machine.
It can be consumed by the NixOS configuration repository or evaluated as a
standalone Home Manager flake.

`common/` contains the configuration used by every represented machine.
`hosts/` contains each machine's user-environment differences. The directory
name is the join key shared with `configuration-nix`: `ugly-rod`, for example,
is exported as both `homeModules.ugly-rod` and
`homeConfigurations.ugly-rod`.

For standalone use, the host needs Nix with flakes enabled, an `x86_64-linux`
Linux environment, and the `monadix` account at `/home/monadix`. It also needs
access to the SOPS age key at `~/.config/sops/age/key.txt`, a systemd user
session, FUSE support for the Zed wrapper, and an X11 graphical environment for
the desktop configuration.
