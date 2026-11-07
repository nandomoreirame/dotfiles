# dotfiles

Public Arch Linux (CachyOS) + Niri + Noctalia foundation: testable, personal-data gated, overlay-ready.

Setting up a new Arch machine from scratch still costs a full day of hand work. Copying somebody else's dotfiles also copies their identity, apps and secrets. This repository starts empty of features and ships the machinery that keeps a public clone clean: MIT license, BATS from pinned submodules, a personal-data gate, CI and a private-overlay contract.

## Status

**Under construction.** Milestone 1 (helpers) landed eight tested optional scripts under [`bin/`](bin/README.md). Do not use this as a daily driver yet; later milestones will migrate more configs and PATH wiring.

## Why

A public dotfiles repo that cannot prove it is clean will leak CPF numbers, LAN addresses and home paths the first time someone copies a script. Starting with a license, a recursive-clone test runner, `scripts/public-check` and CI means every later migration lands in a repo that can fail the build when personal data sneaks in.

## Requirements

- Arch Linux or CachyOS
- Niri (Wayland compositor)
- Noctalia v5 (shell)
- zsh

## Quick start

```bash
git clone --recurse-submodules git@github.com:nandomoreirame/dotfiles.git
cd dotfiles
bash tests/run-tests
bash scripts/public-check .
```

`tests/run-tests` needs the BATS submodules. If you cloned without `--recurse-submodules`, run `git submodule update --init --recursive`.

## Usage

| Command | Purpose |
|---|---|
| `bash tests/run-tests [path]` | Run the BATS suite (`unit` / `integration` groups, or a file/dir) |
| `bash scripts/public-check [--staged] [path]` | Fail on personal data, forbidden paths and (when installed) gitleaks |
| `bash scripts/simulate-clean-clone` | Clone into a temp dir and re-run tests, shellcheck and the gate |

Optional helper scripts live under [`bin/`](bin/README.md) (see that table for PATH, needs and privileges). The private overlay lives outside this repo. See [private/private-overlay.md](private/private-overlay.md) and [private/README.md](private/README.md).

## Security

The foundation only reads tracked files for the personal-data gate and runs local shell checks. Optional helpers under [`bin/`](bin/README.md) include privileged and network-talking scripts (`sys-btrfs-backup`, `sys-clean-cache`, `localsend-clip`, `droidcam-ctl`); none of them run unless you invoke them. See that file's Security section for details.

Later milestones will list every global git hook and piped installer they add. Treat any unreviewed script as untrusted and run `scripts/public-check` before you push.

Report security issues privately to the maintainer; do not open a public issue with secrets, hostnames or personal data.

## Contributing

PRs are welcome once the foundation is green. See [CONTRIBUTING.md](CONTRIBUTING.md) for the test command, the personal-data rule and English-only prose.

## License

MIT. Copyright (c) 2026 Fernando Moreira Costa. See [LICENSE](LICENSE).
