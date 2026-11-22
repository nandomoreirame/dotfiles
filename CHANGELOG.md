# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Breaking:** the CLI uses noun-verb subcommands separated by spaces. `dotfiles packages install|remove --manager <pacman|aur|flatpak|node|sh>` replaces `pacman:install`, `aur:install`, `flatpak:install`, `node:install`, `sh:install`, `apps:install` and the matching `:remove` commands. `langs install`, `fonts install`, `setup run <name>`, `links create [--files|--paths]`, `links verify` and `status` replace `langs:install`, `fonts:install`, `setup:run`, `links --all|--files|--paths`, `--verify` and `--status`. `-V` replaces `-v` for the version, `--only <names>` became positional names, and every command has its own `--help`.

### Added

- Niri config with example `monitor.kdl`, empty `private.kdl` hook, and scrubbed binds (no personal apps or paths)
- Noctalia built-in widgets config (`bar.toml`, `plugins.toml` with `enabled = []`, `config.toml`, `user-templates.toml`)
- Desktop helpers: `niri-*` (except hardware-specific), `nocta` / `nocta-hold` / `noctalia-restart` / `noctalia-plugins-link` (`NOCTALIA_PLUGIN_AUTHOR`), `webapp-*`, `game-mode` (`GAME_MODE_APPS`, `--dry-run`)
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
