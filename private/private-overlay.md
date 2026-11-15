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
| `bin/` | Executables prepended to `PATH` by `.zshenv` when the directory exists |
| `shell/` | `*.zsh` files sourced by `.zshrc` in name order |
| `shell/10-personal.zsh` | Suggested home for AI wrappers (`claude`/`codex`/`commit` with permissions disabled), `chrome-insecure`, token env files and folder aliases |
| `links.conf` | Symlink map merged after the public one |
| `packages/` | `*.list` package picks for the installer |
| `setup/` | `registry.conf` and one-shot setup steps |
| `espanso/` | Private Espanso matches (`base.yml`, `personal.yml`) |
| `configs/opencode/opencode.json` | MCP server list for OpenCode (linked via private `links.conf`) |
| `configs/solaar/rules.yaml` | Mouse button map for one device |
| `configs/applications/input-remapper-gtk.desktop` | System-Python override for the input-remapper GUI |
| `configs/themes/terminal-noir/devnull-tui.json` | Theme entry for a private TUI |
| `shell/` (`DOTFILES_SPELLLANG=...`) | Extra Neovim spell locales (public default is English) |
| `profiles/` | Host or role profiles |
| `docs/` | Private notes (never published) |

Use [README.md](README.md) in this directory as the starting point: put your files here, or clone your real overlay elsewhere and set `DOTFILES_PRIVATE`. Because git ignores everything in `private/` except these two documents, never track overlay content from this repository.

## Wiring already in place

- `.zshenv` prepends `$DOTFILES/private/bin` to `PATH` when that directory exists
- `.zshrc` sources `lib/private.sh`, then each `private/shell/*.zsh` in name order
- `dotfiles links` merges `private/links.conf` after the public map
- package lists and the setup registry merge `private/packages/*.list` and `private/setup/registry.conf`
- a missing overlay is a silent no-op everywhere

Do not commit anything under `/private/` in this repository except the two tracked documents (`.gitignore` already ignores the rest).

## Desktop files kept private

| Overlay path | Links to | Why private |
|---|---|---|
| `configs/niri/private.kdl` | `.config/niri/private.kdl` | Personal binds, window rules, OBS/daybar shortcuts |
| `configs/niri/monitor.kdl` | `.config/niri/monitor.kdl` | Machine-specific outputs and positions |
| `configs/noctalia/bar.toml` | `.config/noctalia/bar.toml` | Author plugin widgets on the bar |
| `configs/noctalia/plugins.toml` | `.config/noctalia/plugins.toml` | Enabled plugin ids and settings |
| `bin/utils/niri-hdmi-automode` | (PATH via `private/bin`) | TV-model-specific HDMI mode watcher |
| `bin/utils/audio-jack-autoswitch` | (PATH via `private/bin`) | Laptop combo-jack profile switcher |
| `bin/utils/rdo-solo*` | (PATH via `private/bin`) | Homelab RDO solo-session helpers |

Set `NOCTALIA_PLUGIN_AUTHOR` in a private shell snippet so `nocta` and `noctalia-plugins-link` target your plugin namespace.
