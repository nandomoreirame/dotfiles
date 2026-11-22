# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Breaking:** `webapp install|list|remove|launch|browser` replaces `webapp-install`, `webapp-remove`, `webapp-launch` and `webapp-browser`. Interactive `install` asks for name, URL and icon (empty icon fetches the site favicon); `list` prints kind and name only; colors follow `NO_COLOR` and the TTY.
- The author's desktop configs (niri `private.kdl` / `monitor.kdl`, Noctalia `bar.toml` / `plugins.toml` / palettes, Umbriel `private.toml` / `outputs.toml`, espanso, lazygit, Solaar, input-remapper) moved public under `configs/`. Files with personal data stay as `*.private.*` symlinks into the private overlay, ignored by git
- Every app list is public (`apps` groups for pacman, AUR and Flatpak); the private `baseline` profile and package picks are gone
- Installs are idempotent: pacman runs one `-Syu` before installing only the missing packages, AUR matches `-bin`/`-git` variants, shell apps skip oh-my-zsh, mise and docker (or its provider) when present, links keep targets that already resolve to the source, and setup steps check state first
- `dotfiles install` keeps going after a failed package step and ends with a summary of the failed steps and items
- Umbriel: no bare-Super launcher bind (Ctrl+Space stays), every scratchpad sets `hide_when_empty`, and scratchpad keys go through `umbriel-scratchpad`
- Luciole replaces Nautilus as the default file manager (`Mod+Shift+F`, `inode/directory`)
- mise no longer installs a global Python, so system tools such as virt-manager use `/usr/bin/python`
- **Breaking:** the CLI uses noun-verb subcommands separated by spaces. `dotfiles packages install|remove --manager <pacman|aur|flatpak|node|sh>` replaces `pacman:install`, `aur:install`, `flatpak:install`, `node:install`, `sh:install`, `apps:install` and the matching `:remove` commands. `langs install`, `fonts install`, `setup run <name>`, `links create [--files|--paths]`, `links verify` and `status` replace `langs:install`, `fonts:install`, `setup:run`, `links --all|--files|--paths`, `--verify` and `--status`. `-V` replaces `-v` for the version, `--only <names>` became positional names, and every command has its own `--help`.

### Added

- `dotfiles tui`: guided installer on tui.sh (vendored as the `lib/vendor/tuish` submodule). A prerequisites gate (git, curl, sudo, base-devel, an AUR helper, no pending updates from `checkupdates`) unlocks a checklist of install steps; runs happen in the background with a live log tail, per-step status, one `sudo -v` plus keepalive, and full logs in `~/.cache/dotfiles/`
- `umbriel-scratchpad toggle|close`: adopts or minimizes orphaned scratchpad windows, and `Ctrl+Q` / `Mod+Q` close a window for good without leaving an invisible click-blocking overlay
- `vm` package group (qemu-desktop, libvirt, virt-manager, dnsmasq, edk2-ovmf, swtpm) and the `libvirt.sh` setup step (service, group, default network)
- Install failure summary (`_failure_record`) and install/TUI screenshots in the README
- `.gitleaks.toml` that keeps the default rules and skips vendored code
- Niri config with example `monitor.kdl`, `private.kdl` hook, and scrubbed binds (no personal apps or paths)
- Noctalia config (`bar.toml`, `plugins.toml`, `config.toml`, `user-templates.toml`, palettes)
- Desktop helpers: `niri-*` (except hardware-specific), `nocta` / `nocta-hold` / `noctalia-restart` / `noctalia-plugins-link` (`NOCTALIA_PLUGIN_AUTHOR`), `webapp`, `game-mode` (`GAME_MODE_APPS`, `--dry-run`)
- File-level links for niri and Noctalia so the private overlay can replace individual desktop files
- Terminal Noir theme sources, generator (`scripts/themes/build-terminal-noir`) and per-app theme files for ghostty, tmux, bat, micro, Neovim, VS Code, GTK, Chrome and Obsidian
- Terminal configs (ghostty, tmux, bat, micro) with palette-only colors and English comments
- Neovim LazyVim config with `DOTFILES_SPELLLANG` (default English) and no personal paths
- VS Code settings/keybindings/snippets without MCP servers; linked theme package under `configs/vscode/terminal-noir/`
- Desktop flags and overrides: GTK, chrome/electron flags, Chromium/Chrome `.desktop` files, fcitx5, generic espanso matches
- Generic zsh/bash environment (`.zshenv`, `.zshrc`, `.bashrc`, `.profile`, `.p10k.zsh`, `.oh-my-zsh/custom/`) that resolves `$DOTFILES` from the clone symlink and loads `private/shell/*.zsh` when present
- Arch packages for powerlevel10k, zsh-autosuggestions and zsh-syntax-highlighting (loaded from `/usr/share`, skipped when absent)
- Generic `.gitconfig` and `configs/git/*` without identity, signing or hooks (those stay in `~/.gitconfig.local`)
- Theme-free app configs: btop, fastfetch, glow, lazygit, starship, mise, plus curl/wget/prettier rc files
- Profile switching (`dotfiles profile list|show|switch`) for Git identity and gcloud configs; thin wrappers `bin/profile` and `bin/git/git-profile`
- Opt-in Git hooks (`dotfiles hooks enable|disable|status`): guard blocks home paths and secrets; strip removes Co-Authored-By / Generated-with lines (off until enabled)
- New-machine install flow (`./install.sh` and `dotfiles install`) with `--dry-run`, `--yes`, `--no-remote` and `--group`
- Data-driven package lists under `packages/` with a private overlay merge (`private/packages/*.list`)
- pacman / AUR / Flatpak / npm installers, verified oh-my-zsh download, fonts via pacman, setup registry
- `dotfiles init` (local git identity) and `dotfiles doctor` (prerequisites, links, packages, identity)
- Clone-relative `dotfiles` CLI (`links`, `--status`, `--verify`, `--help`, `--version`)
- Shared public/private link mapping with backups, overlay precedence and idempotent creation
- Terminal-aware `_confirm` and `_choose` prompts with explicit automation controls
- Migrated English base libraries, CLI integration tests and shellcheck coverage for all modules
- Eight tested optional helpers under `bin/sys/` and `bin/utils/` (`sys-btrfs-backup`, `sys-clean-cache`, `clean-claude-sessions`, `notify-open`, `video-to-gif`, `localsend-clip`, `espanso-hotplug`, `droidcam-ctl`) with BATS coverage, `bin/README.md` table and CI shellcheck on `bin/*/*`
- MIT license and English README, CONTRIBUTING and THIRD-PARTY notes
- BATS test runner via pinned git submodules (`tests/run-tests`)
- Personal-data gate (`scripts/public-check`) and allowfile
- Private overlay contract (`lib/private.sh`, `private/README.md`, `private/private-overlay.md`)
- Clean-clone simulation (`scripts/simulate-clean-clone`)
- GitHub Actions CI (shellcheck, tests, public-check, gitleaks)
- Pull request and issue templates; this changelog

### Fixed

- `.zshrc` defaults `ZSH` to `~/.oh-my-zsh`, so a graphical terminal without a login shell loads oh-my-zsh aliases and functions again
- Noctalia wallpaper directory and lock hook point at paths that exist
