# Third-party software

This repository vendors the following projects as git submodules (test tooling under `tests/bats/lib/`, runtime libraries under `lib/vendor/`):

| Project | License | Path |
|---|---|---|
| [bats-core](https://github.com/bats-core/bats-core) | MIT | `tests/bats/lib/bats-core` |
| [bats-support](https://github.com/bats-core/bats-support) | MIT | `tests/bats/lib/bats-support` |
| [bats-assert](https://github.com/bats-core/bats-assert) | CC0-1.0 | `tests/bats/lib/bats-assert` |
| [bats-file](https://github.com/bats-core/bats-file) | MIT | `tests/bats/lib/bats-file` |
| [tui.sh](https://github.com/alganet/tuish) | ISC | `lib/vendor/tuish` (pinned commit; loaded only by `bin/utils/dotfiles-tui`) |

### Bundled editor themes

| Project | License | Path |
|---|---|---|
| [Catppuccin for Micro](https://github.com/catppuccin/micro) | MIT | `configs/micro/colorschemes/catppuccin-*.micro` |

Terminal Noir theme files in this repository are original (MIT, same as the repo). The Chrome `Cached Theme.pak` is a binary produced by Chrome from the adjacent `manifest.json`; treat the manifest as the source.

This repository ships **no fonts**, **no wallpapers** and **no brand icons**. Any such assets belong in a private overlay or a separate media repo, never in the public tree.
