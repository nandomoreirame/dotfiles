# Private overlay

This directory is the default home of the private overlay (`DOTFILES_PRIVATE`, default `$DOTFILES/private`). Everything in it is ignored by git except this file and `private-overlay.md`. A missing overlay is never an error.

The author's desktop configs are public under `configs/`. The overlay keeps only what identifies a person or a machine: the real files behind the public `*.private.*` symlinks, machine helpers and secrets loaders.

## Layout

```
private/
  bin/           # executables on PATH (machine and homelab helpers)
  env/           # *.zsh sourced by .zshenv (API key loaders)
  shell/         # *.zsh sourced by .zshrc in name order
  configs/       # targets of the public configs/**/*.private.* symlinks
    espanso/match/base.yml, personal.yml
    opencode/opencode.json
    .gitconfig
  links.conf     # symlink map merged after the public one
  packages/      # *.list package picks (may stay empty)
  setup/         # registry.conf and one-shot steps
  profiles/      # host or role profiles
  docs/          # private notes (never published)
```

## Quick start

Put your files straight into this directory, or keep the overlay in its own repository elsewhere and point to it:

```bash
git clone git@example.com:you/dotfiles-private.git "$HOME/src/dotfiles-private"
export DOTFILES_PRIVATE="$HOME/src/dotfiles-private"
```

Pointing `DOTFILES_PRIVATE` elsewhere is the recommended setup when the overlay has its own git history: a repository cannot live in this directory without seeing these two tracked documents as foreign files. The public `*.private.*` symlinks point at `private/configs/`, so with an overlay elsewhere, link that path to it (`ln -s "$DOTFILES_PRIVATE" private`) or replace the symlinks.

See [private-overlay.md](private-overlay.md) for the full contract.
