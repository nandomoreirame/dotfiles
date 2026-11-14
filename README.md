# dotfiles

Setting up another Arch machine means repeating package installs, config links and identity setup. Copying somebody else's dotfiles can also copy their identity, apps and secrets.

This repository separates shareable configuration from a private overlay, provides a tested link manager and install flow, and keeps a personal-data gate in CI.

## Status

The CLI and the new-machine install flow work on Arch Linux / CachyOS. Profiles and global git hooks arrive next; public application configs and the desktop shell migrate in later milestones.

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
dotfiles doctor
dotfiles --verify
```

The public `configs/links.conf` is documented but empty until the config migrations land. Add `[files]` names relative to `configs/`, or `[paths]` rows in the form `configs/tool.conf | .config/tool.conf |`. `[paths:arch]` adds Arch-specific rows. Targets are relative to HOME; paths containing parent traversal are rejected.

`DOTFILES` defaults to the clone containing the executable. `DOTFILES_PRIVATE` defaults to its `private/` directory and can point to an external overlay. Private entries are loaded after public entries and replace the same target. See [private/README.md](private/README.md) and [private/private-overlay.md](private/private-overlay.md).

| Command | Purpose |
|---|---|
| `./install.sh` | New-machine flow (prerequisites, AUR helper, packages, fonts, runtimes, links, setup) |
| `dotfiles links --files` / `--paths` | Create only file or path links |
| `dotfiles pacman:install` / `aur:install` / `flatpak:install` / `node:install` | Install from the matching list |
| `dotfiles apps:install` | Run pacman, AUR, Flatpak, Node, sh and langs |
| `dotfiles fonts:install` | Install the pacman fonts group |
| `dotfiles setup` / `setup:run <name>` | Run auto setup scripts, or one by name |
| `dotfiles init` | Write `~/.gitconfig.local` identity |
| `dotfiles doctor` | Check prerequisites, links, packages and identity |
| `dotfiles --verify` | Report missing, broken and foreign links |
| `dotfiles --status` | Check links, PATH, environment and packages |
| `bash tests/run-tests [path]` | Run unit and integration tests |
| `bash scripts/public-check [--staged] [path]` | Personal-data gate |

Shared install flags: `--dry-run`, `--yes`, `--no-remote`, `--group <name>`, `--only <names>`. For automation, set `DOTFILES_YES=1`; `DOTFILES_PROMPT_STDIN=1` permits scripted stdin answers. Optional helpers are listed in [bin/README.md](bin/README.md).

## Security

### Network fetches

| Source | How | Verification |
|---|---|---|
| pacman packages | `sudo pacman -S` | Arch package signatures |
| AUR packages | `yay` / `paru` (or building `yay` once) | PKGBUILD reviewed by the helper; you choose the packages |
| Flatpak apps | `flatpak install flathub ...` | Flathub remote |
| npm globals | `npm install -g` | npm registry |
| oh-my-zsh installer | download to a temp file, then `sh <file> --unattended` | URL pinned to a commit in [`scripts/remote-installers.conf`](scripts/remote-installers.conf); SHA-256 checked before run |

`--no-remote` skips the oh-my-zsh download. Fonts come from Arch packages (`packages/pacman.list` fonts group); the installer does not download font archives and does not delete `~/.fonts`.

### Privileges

`sudo` is used for pacman installs, enabling the docker service and adding the user to the docker group. Removals ask for confirmation unless `DOTFILES_YES=1`.

### Local changes

The CLI creates symlinks under HOME. Conflicting real files move to unique `.bak.*` siblings. Overlay entries can select different sources; review both manifests before linking. The CLI opens no network listener. Optional helpers under [`bin/`](bin/README.md) include privileged and network-talking scripts; none run unless you invoke them.

Report security issues privately to the maintainer; do not open a public issue with secrets, hostnames or personal data.

## Contributing

PRs are welcome once the foundation is green. See [CONTRIBUTING.md](CONTRIBUTING.md) for the test command, the personal-data rule, English-only prose and the VM smoke test.

## License

MIT. Copyright (c) 2026 Fernando Moreira Costa. See [LICENSE](LICENSE).
