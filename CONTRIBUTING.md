# Contributing

## Setup

```bash
git clone --recurse-submodules git@github.com:nandomoreirame/dotfiles.git
cd dotfiles
```

If the clone skipped submodules:

```bash
git submodule update --init --recursive
```

## Tests

```bash
bash tests/run-tests
# or a single file / group:
bash tests/run-tests tests/unit/repo
bash tests/run-tests unit
```

Always run under a real `TERM` when diagnosing failures. The runner itself rewrites empty/`dumb` to `xterm-256color`.

When the runner has no terminal on stdin (CI, agents, editors), redirect it from `/dev/null` so a stub that reads stdin cannot hang the run:

```bash
bash tests/run-tests tests/unit/bin </dev/null
```

The `dotfiles tui` end-to-end tests drive the real TUI in a pseudo-terminal through util-linux `script` and set its size with `stty rows 30 cols 100`; they need the `lib/vendor/tuish` submodule.

## Personal data gate

Before every commit:

```bash
bash scripts/public-check .
# or only what you staged:
bash scripts/public-check --staged
```

CI also runs gitleaks with `.gitleaks.toml`, which keeps the default rules and skips `lib/vendor/`.

**No personal data** may enter the public tree: CPF/CNPJ, phone numbers, private IPv4 ranges, `/home/<user>` or `/Users/<user>` paths, personal e-mails, secrets, or anything under `private/`. Tests that need samples must assemble them at run time (string concatenation), never as literals in the file.

## Language

README, docs, comments and runtime messages are **English**. Identifiers stay English.

## Pull requests

Use the pull request template. Keep the change small, add tests with the feature, and leave `docs/` (specs, plans, reviews) untracked: that directory is local-only and fully gitignored. The only tracked files under `private/` are its two documents, and `*.private.*` files are ignored symlinks into the overlay.

## VM smoke test

On a fresh Arch VM (or a throwaway user):

```bash
git clone --recurse-submodules git@github.com:nandomoreirame/dotfiles.git
cd dotfiles
./install.sh --dry-run
./install.sh
dotfiles init
dotfiles doctor
```

Automated tests stub pacman/AUR/Flatpak/npm and never install real packages. The VM run is the proof that the live flow works.

## Conventions

Bash modules resolve the clone when `DOTFILES` is unset:

```bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
```

Source code siblings relative to the module location; `DOTFILES` may point to a
separate config tree. zsh has no `BASH_SOURCE`; shell configs set `DOTFILES` themselves.
