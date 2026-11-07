# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Eight tested optional helpers under `bin/sys/` and `bin/utils/` (`sys-btrfs-backup`, `sys-clean-cache`, `clean-claude-sessions`, `notify-open`, `video-to-gif`, `localsend-clip`, `espanso-hotplug`, `droidcam-ctl`) with BATS coverage, `bin/README.md` table and CI shellcheck on `bin/*/*`
- MIT license and English README, CONTRIBUTING and THIRD-PARTY notes
- BATS test runner via pinned git submodules (`tests/run-tests`)
- Personal-data gate (`scripts/public-check`) and allowfile
- Private overlay contract (`lib/private.sh`, `private/README.md`, `private/private-overlay.md`)
- Clean-clone simulation (`scripts/simulate-clean-clone`)
- GitHub Actions CI (shellcheck, tests, public-check, gitleaks)
- Pull request and issue templates; this changelog
