# Private overlay contract

A public clone of this repository must stay free of personal data. Anything that is yours alone (SSH host aliases, LAN hostnames, commercial fonts, machine-specific packages, private docs) lives in a **private overlay**: a separate repository or directory pointed at by `DOTFILES_PRIVATE`.

## Variable

| Variable | Default | Meaning |
|---|---|---|
| `DOTFILES` | `$HOME/.dotfiles` | Public tree root |
| `DOTFILES_PRIVATE` | `$DOTFILES/private` | Overlay root (override to point at a clone elsewhere) |

`lib/private.sh` defines `_private_path <rel>` (echoes `$DOTFILES_PRIVATE/<rel>`) and `_private_has <rel>` (exit 0 when that path exists). Sourcing it when the overlay is missing is never an error and produces no output.

## Layout

| Path | Role |
|---|---|
| `bin/` | Executables prepended to `PATH` |
| `shell/` | `*.zsh` files sourced in name order |
| `links.conf` | Symlink map merged after the public one |
| `packages/` | `*.list` package picks for the installer |
| `setup/` | `registry.conf` and one-shot setup steps |
| `espanso/` | Private Espanso matches |
| `profiles/` | Host or role profiles |
| `docs/` | Private notes (never published) |

Use [README.md](README.md) in this directory as the starting point: put your files here, or clone your real overlay elsewhere and set `DOTFILES_PRIVATE`. Because git ignores everything in `private/` except these two documents, never track overlay content from this repository.

## Wiring (later milestones)

This foundation only ships the helpers and the docs. Later milestones will:

- source `lib/private.sh` from `.zshenv` and prepend `_private_path bin` to `PATH` when present
- merge `links.conf` after the public map
- feed `packages/*.list` and `setup/registry.conf` into the installer
- leave a missing overlay as a silent no-op everywhere

Until those hooks land, keep the overlay offline and do not commit anything under `/private/` in this repository (`.gitignore` already ignores it).
