# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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
