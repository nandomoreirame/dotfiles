# Private overlay contract

A public clone of this repository must stay free of personal data. Anything that is yours alone (e-mail and documents in text expansions, Git identity, MCP servers on your LAN, machine-specific helpers, API keys, private docs) lives in a **private overlay**: a separate repository or directory pointed at by `DOTFILES_PRIVATE`.

## Variable

| Variable | Default | Meaning |
|---|---|---|
| `DOTFILES` | `$HOME/.dotfiles` | Public tree root |
| `DOTFILES_PRIVATE` | `$DOTFILES/private` | Overlay root (override to point at a clone elsewhere) |

`lib/private.sh` defines `_private_path <rel>` (echoes `$DOTFILES_PRIVATE/<rel>`) and `_private_has <rel>` (exit 0 when that path exists). Sourcing it when the overlay is missing is never an error and produces no output.

## Public `*.private.*` files

Private configs sit next to the public ones as `<name>.private.<ext>` (or `<dotfile>.private`). Each one is a relative symlink into `private/configs/`, where the real file is versioned by the overlay. `.gitignore` ignores `*.private.*` and `*.private`, so the public repository never tracks them.

| Public symlink | Overlay file | Linked by |
|---|---|---|
| `configs/espanso/match/base.private.yml` | `configs/espanso/match/base.yml` | the espanso match directory (espanso loads every `*.yml`) |
| `configs/espanso/match/personal.private.yml` | `configs/espanso/match/personal.yml` | same |
| `configs/opencode/opencode.private.json` | `configs/opencode/opencode.json` | private `links.conf` to `.config/opencode/opencode.json` |
| `configs/.gitconfig.private` | `configs/.gitconfig` | private `links.conf` to `.gitconfig` |

Without the overlay these symlinks dangle: espanso skips them and the private `links.conf` that would link the rest does not exist.

## Layout

| Path | Role |
|---|---|
| `bin/` | Executables prepended to `PATH` by `.zshenv` when the directory exists |
| `env/` | `*.zsh` files sourced by `.zshenv` in name order, for every zsh (also non-interactive); keep them fast and silent, e.g. loading API keys from files outside git |
| `shell/` | `*.zsh` files sourced by `.zshrc` in name order (see `private/shell` wiring below) |
| `shell/10-personal.zsh` | Suggested home for AI wrappers (`claude`/`codex`/`commit` with permissions disabled), `chrome-insecure`, token env files and folder aliases |
| `shell/` (`DOTFILES_SPELLLANG=...`) | Extra Neovim spell locales (public default is English) |
| `configs/` | Targets of the public `*.private.*` symlinks (espanso `base.yml` and `personal.yml`, `opencode.json`, `.gitconfig`) |
| `links.conf` | Symlink map merged after the public one |
| `packages/` | `*.list` package picks for the installer; every app is public now, so these lists may stay empty |
| `setup/` | `registry.conf` and one-shot setup steps |
| `profiles/` | Host or role profiles |
| `docs/` | Private notes (never published) |

Use [README.md](README.md) in this directory as the starting point: put your files here, or clone your real overlay elsewhere and set `DOTFILES_PRIVATE`. Because git ignores everything in `private/` except these two documents, never track overlay content from this repository.

## Private links.conf

The overlay map links only the files that must not exist without it:

```
[paths]
configs/.gitconfig.private | .gitconfig
configs/opencode/opencode.private.json | .config/opencode/opencode.json
```

An overlay entry with the same destination as a public one wins.

## Wiring already in place

- `.zshenv` prepends `$DOTFILES/private/bin` to `PATH` when that directory exists
- `.zshenv` sources each `private/env/*.zsh` in name order (honors `DOTFILES_PRIVATE`)
- `.zshrc` sources `lib/private.sh`, then each `private/shell/*.zsh` in name order
- `dotfiles links create` merges `private/links.conf` after the public map
- package lists and the setup registry merge `private/packages/*.list` and `private/setup/registry.conf`
- a missing overlay is a silent no-op everywhere

Do not commit anything under `/private/` in this repository except the two tracked documents (`.gitignore` already ignores the rest).

## Desktop files

The author's niri and Noctalia files are public and linked by `configs/links.conf`: niri `private.kdl` (personal binds and window rules) and `monitor.kdl` (outputs), Noctalia `bar.toml`, `plugins.toml`, `config.toml` and palettes, Umbriel `private.toml` and `outputs.toml`, Solaar `rules.yaml` and the input-remapper `.desktop` override. To use your own, add an entry with the same destination to the private `links.conf`; it replaces the public link.

Helpers tied to one machine or one homelab stay in the overlay `bin/`:

| Overlay path | Why private |
|---|---|
| `bin/niri-hdmi-automode` | TV-model-specific HDMI mode watcher |
| `bin/audio-jack-autoswitch` | Laptop combo-jack profile switcher |
| `bin/rdo-solo*` | Homelab RDO solo-session helpers |

Set `NOCTALIA_PLUGIN_AUTHOR` in a private shell snippet so `nocta` and `noctalia-plugins-link` target your plugin namespace.
