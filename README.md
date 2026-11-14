# dotfiles

Setting up another Arch machine means repeating config links and checking that no personal settings were copied.

Copying somebody else's dotfiles can also copy their identity, apps and secrets. This repository separates shareable configuration from a private overlay and provides a tested link manager plus a personal-data gate.

## Status

**Under construction.** The CLI works, and eight optional helpers are available under [bin/](bin/README.md). Installation arrives in the next milestone; public application configs have not migrated yet.

## Why

A public dotfiles repo that cannot prove it is clean will leak CPF numbers, LAN addresses and home paths the first time someone copies a script. Starting with a license, a recursive-clone test runner, `scripts/public-check` and CI means every later migration lands in a repo that can fail the build when personal data sneaks in.

## Requirements

Arch Linux or CachyOS, Bash 4.3+, Git and GNU coreutils. The optional desktop
helpers target Niri, Noctalia v5 and zsh; the link manager itself needs none of them.

## Quick start

```bash
git clone --recurse-submodules git@github.com:nandomoreirame/dotfiles.git
cd dotfiles
export PATH="$PATH:$PWD/bin"
dotfiles --help
```

## Usage

```bash
dotfiles links --all
dotfiles --verify
```

The public `configs/links.conf` is documented but empty until the config migrations
land. Add `[files]` names relative to `configs/`, or `[paths]` rows in the form
`configs/tool.conf | .config/tool.conf |`. `[paths:arch]` adds Arch-specific rows.
Targets are relative to HOME; paths containing parent traversal are rejected.

`DOTFILES` defaults to the clone containing the executable. `DOTFILES_PRIVATE`
defaults to its `private/` directory and can point to an external overlay. Private
entries are loaded after public entries and replace the same target. See
[private/README.md](private/README.md) and [private/private-overlay.md](private/private-overlay.md).
Overlay `[files]` names resolve under `DOTFILES_PRIVATE/configs/`; `[paths]` sources
starting with `private/` resolve under `DOTFILES_PRIVATE/`.

| Command | Purpose |
|---|---|
| `dotfiles links --files` / `--paths` | Create only file or path links |
| `dotfiles --verify` | Report missing, broken and foreign links; fail on a problem |
| `dotfiles --status` | Check links, existing bin directories in PATH and environment |
| `dotfiles --version` | Print the CLI version and config root |
| `bash tests/run-tests [path]` | Run unit and integration tests using the pinned BATS submodules |
| `bash scripts/public-check [--staged] [path]` | Check tracked or staged content for personal data and secrets |
| `bash scripts/simulate-clean-clone` | Re-run tests, shellcheck and the gate in a clean recursive clone |

Missing sources require confirmation before they are skipped. For automation, set
`DOTFILES_YES=1`; `DOTFILES_PROMPT_STDIN=1` explicitly permits scripted stdin answers.
`--status` expects the clone's existing `bin/` subdirectories on PATH too. Optional
helper scripts, their PATH setup and privileges are listed in [bin/README.md](bin/README.md).

## Security

The CLI reads local config files and creates symlinks under HOME. Conflicting real files and directories move to unique `.bak.*` siblings; existing symlinks may be replaced. Overlay entries can select different sources, so review both manifests before linking. The CLI opens no network listener and makes no network requests. Clone and simulation commands use Git to fetch the repository and its submodules; the gate invokes gitleaks when installed. Optional helpers under [`bin/`](bin/README.md) include privileged and network-talking scripts (`sys-btrfs-backup`, `sys-clean-cache`, `localsend-clip`, `droidcam-ctl`); none of them run unless you invoke them. See that file's Security section for details.

Later milestones will list every global git hook and piped installer they add. Treat any unreviewed script as untrusted and run `scripts/public-check` before you push.

Report security issues privately to the maintainer; do not open a public issue with secrets, hostnames or personal data.

## Contributing

PRs are welcome once the foundation is green. See [CONTRIBUTING.md](CONTRIBUTING.md) for the test command, the personal-data rule and English-only prose.

## License

MIT. Copyright (c) 2026 Fernando Moreira Costa. See [LICENSE](LICENSE).
