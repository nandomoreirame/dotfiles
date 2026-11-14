# dotfiles

Setting up another Arch machine means repeating package installs, config links and identity setup. Copying somebody else's dotfiles can also copy their identity, apps and secrets.

This repository separates shareable configuration from a private overlay, provides a tested link manager and install flow, and keeps a personal-data gate in CI.

## Status

The CLI, new-machine install flow, profiles, opt-in Git hooks and the generic shell/Git configs work on Arch Linux / CachyOS. Theme-coupled app configs and the Niri/Noctalia desktop migrate in later milestones.

## Why

A public dotfiles repo that cannot prove it is clean will leak CPF numbers, LAN addresses and home paths the first time someone copies a script. Starting with a license, a recursive-clone test runner, `scripts/public-check` and CI means every later migration lands in a repo that can fail the build when personal data sneaks in.

## Requirements

Arch Linux or CachyOS, Bash 4.3+, Git and GNU coreutils. The optional desktop helpers target Niri, Noctalia v5 and zsh; the install flow itself needs pacman and (for AUR packages) an AUR helper.

## New machine

Preview every step without changing the system:

```bash
git clone --recurse-submodules git@github.com:nandomoreirame/dotfiles.git
cd dotfiles
./install.sh --dry-run
```

Then install:

```bash
./install.sh
# or accept every confirmation:
./install.sh --yes
```

Limit packages to one group, or skip the verified remote installer:

```bash
./install.sh --group fonts --dry-run
./install.sh --no-remote --yes
```

After install:

```bash
export PATH="$PATH:$PWD/bin"
dotfiles init
dotfiles doctor
chsh -s /bin/zsh
# log out and back in
```

### Package groups

Public package lists live under [`packages/`](packages/) with these pacman groups: `core`, `shell`, `containers`, `fonts`, `desktop`. AUR, Flatpak and npm lists sit beside them. Personal picks go in [`private/packages/`](private/README.md) (`*.list`) and are merged after the public files; they never enter git.

## Quick start (existing clone)

```bash
git clone --recurse-submodules git@github.com:nandomoreirame/dotfiles.git
cd dotfiles
export PATH="$PATH:$PWD/bin"
dotfiles --help
```

## Usage

```bash
dotfiles links --all
dotfiles pacman:install --group fonts --dry-run --yes
dotfiles apps:install --dry-run --yes
dotfiles setup
dotfiles init
dotfiles profile switch personal
dotfiles hooks enable
dotfiles doctor
dotfiles --verify
```

`configs/links.conf` maps the shell, Git and theme-free app configs shipped below. Add `[files]` names relative to `configs/`, or `[paths]` rows in the form `configs/tool.conf | .config/tool.conf`. `[paths:arch]` adds Arch-specific rows. Targets are relative to HOME; paths containing parent traversal are rejected.

`DOTFILES` defaults to the clone containing the executable (`.zshenv` derives it from its own symlink). `DOTFILES_PRIVATE` defaults to its `private/` directory and can point to an external overlay. Private entries are loaded after public entries and replace the same target. See [private/README.md](private/README.md) and [private/private-overlay.md](private/private-overlay.md).

## Shell and Git configs

| Path | Role |
|---|---|
| `.zshenv` | Resolves `$DOTFILES`, builds `PATH` once, prepends `private/bin` when present |
| `.zshrc` / `.bashrc` / `.profile` | Interactive shell; sources `private/shell/*.zsh` in name order |
| `.p10k.zsh` | Powerlevel10k config (theme package from Arch) |
| `.oh-my-zsh/custom/` | Generic aliases and helpers (no unsafe defaults) |
| `.gitconfig` + `configs/git/*` | Generic Git defaults; identity/signing/hooks stay in `~/.gitconfig.local` |
| `btop`, `fastfetch`, `glow`, `lazygit`, `starship.toml`, `mise` | Theme-free app configs |

`powerlevel10k`, `zsh-autosuggestions` and `zsh-syntax-highlighting` come from Arch packages under `/usr/share` and are skipped when absent. They are listed in `packages/pacman.list`.

**Intentionally absent from the public tree:** `rm`/`cp`/`mv` keep their normal defaults (no recursive force aliases). The AI wrappers that disable permission prompts (`claude`, `codex`, `commit`) and `chrome-insecure` are not shipped; put them in `private/shell/` if you want them. Git identity and signing come from `dotfiles init` / `dotfiles profile`, never from the tracked `.gitconfig`.

| Command | Purpose |
|---|---|
| `./install.sh` | New-machine flow (prerequisites, AUR helper, packages, fonts, runtimes, links, setup) |
| `dotfiles links --files` / `--paths` | Create only file or path links |
| `dotfiles pacman:install` / `aur:install` / `flatpak:install` / `node:install` | Install from the matching list |
| `dotfiles apps:install` | Run pacman, AUR, Flatpak, Node, sh and langs |
| `dotfiles fonts:install` | Install the pacman fonts group |
| `dotfiles setup` / `setup:run <name>` | Run auto setup scripts, or one by name |
| `dotfiles init` | Write `~/.gitconfig.local` identity |
| `dotfiles profile list\|show\|switch <name>` | List or switch Git/gcloud identity profiles |
| `dotfiles hooks enable\|disable\|status` | Opt-in global Git hooks (off by default) |
| `dotfiles doctor` | Check prerequisites, links, packages, identity and profile |
| `dotfiles --verify` | Report missing, broken and foreign links |
| `dotfiles --status` | Check links, PATH, environment, packages and active profile |
| `bash tests/run-tests [path]` | Run unit and integration tests |
| `bash scripts/public-check [--staged] [path]` | Personal-data gate |

Shared install flags: `--dry-run`, `--yes`, `--no-remote`, `--group <name>`, `--only <names>`. For automation, set `DOTFILES_YES=1`; `DOTFILES_PROMPT_STDIN=1` permits scripted stdin answers. Optional helpers are listed in [bin/README.md](bin/README.md). Thin wrappers: `bin/profile` and `bin/git/git-profile` exec into `dotfiles profile`.

## Profiles

A profile holds a Git identity (name, email, signing key), an optional gcloud/Firebase account and project list, plus shell and environment snippets. Tracked templates live under `profiles/linux-arch/`:

- `env.conf`, `shell.conf` (tracked)
- `git-personal.conf.example`, `git-work.conf.example`
- `gcloud-personal.conf.example`, `gcloud-work.conf.example`

Copy an `.example` to the matching real file (for example `git-personal.conf`). Real `git-*.conf` and `gcloud-*.conf` files are gitignored. Then switch:

```bash
dotfiles profile list
dotfiles profile switch personal
dotfiles profile show
```

`dotfiles profile switch` writes the Git identity into `~/.gitconfig.local` (never into the repository) and activates a matching gcloud configuration when `gcloud` is installed. Missing cloud credentials print the `gcloud auth` command to run; the switch never opens a browser on its own.

## Git hooks

Git hooks ship **off by default** (opt-in). Enabling them sets `core.hooksPath` in `~/.gitconfig.local` to this clone's `git-hooks/` directory, so they run in **every repository** on the machine.

```bash
dotfiles hooks enable          # guard only
dotfiles hooks enable guard strip
dotfiles hooks status
dotfiles hooks disable
```

- **guard** (pre-commit): blocks added lines with a `/home/<user>/` path (use `~`, `$HOME` or `%h`) and obvious hard-coded secrets (AWS keys, Slack/GitHub tokens, private keys). Bypass with `git commit --no-verify`. Chains the repository-local `pre-commit` when present.
- **strip** (commit-msg, separate switch): removes `Co-Authored-By`, `Generated with` and robot-emoji signature lines from the commit message. Off unless you pass `strip` to `hooks enable`.

## Security

### Network fetches

| Source | How | Verification |
|---|---|---|
| pacman packages | `sudo pacman -S` | Arch package signatures |
| AUR packages | `yay` / `paru` | PKGBUILD reviewed by the helper; you choose the packages |
| yay bootstrap (once, if no helper) | `git clone` of the AUR `yay` repo, `git checkout` of a pinned commit, then `makepkg -si` | Commit pinned in [`scripts/remote-installers.conf`](scripts/remote-installers.conf); `--noconfirm` only when `DOTFILES_YES=1` so the PKGBUILD can be inspected otherwise |
| Flatpak apps | `flatpak install flathub ...` | Flathub remote |
| npm globals | `npm install -g` | npm registry |
| oh-my-zsh installer | download to a temp file, then `sh <file> --unattended` | URL pinned to a commit in [`scripts/remote-installers.conf`](scripts/remote-installers.conf); SHA-256 checked before run |

`--no-remote` skips the oh-my-zsh download (not the pinned yay bootstrap). Fonts come from Arch packages (`packages/pacman.list` fonts group); the installer does not download font archives and does not delete `~/.fonts`.

### Privileges

`sudo` is used for pacman installs, enabling the docker service and adding the user to the docker group. Removals ask for confirmation unless `DOTFILES_YES=1`.

### Local changes

The CLI creates symlinks under HOME. Conflicting real files move to unique `.bak.*` siblings. Overlay entries can select different sources; review both manifests before linking. The CLI opens no network listener. Optional helpers under [`bin/`](bin/README.md) include privileged and network-talking scripts; none run unless you invoke them.

### Shell startup

`.zshenv`, `.zshrc`, `.bashrc` and `.profile` run on every terminal start. They only read local files from the clone and from `private/shell/` when present; they download nothing and open no network listener. Keep tokens and API keys out of the public tree and load them from the overlay.

### Profiles and hooks

Profile files under `profiles/**/git-*.conf` and `gcloud-*.conf` are gitignored; only `.example` templates are tracked. Identity is written only to `~/.gitconfig.local`. Global hooks stay disabled until `dotfiles hooks enable`; that command sets `core.hooksPath` for every repository on the machine and prints how to run `hooks disable`. The guard redacts matched secrets in its output. The strip hook is a separate opt-in and never runs until enabled.

Report security issues privately to the maintainer; do not open a public issue with secrets, hostnames or personal data.

## Contributing

PRs are welcome once the foundation is green. See [CONTRIBUTING.md](CONTRIBUTING.md) for the test command, the personal-data rule, English-only prose and the VM smoke test.

## License

MIT. Copyright (c) 2026 Fernando Moreira Costa. See [LICENSE](LICENSE).
