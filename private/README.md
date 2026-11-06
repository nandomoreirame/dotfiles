# Private overlay

This directory is the default home of the private overlay (`DOTFILES_PRIVATE`, default `$DOTFILES/private`). Everything in it is ignored by git except this file and `private-overlay.md`. A missing overlay is never an error.

## Layout

```
private/
  bin/           # executables on PATH
  shell/         # *.zsh sourced in name order
  links.conf     # symlink map merged after the public one
  packages/      # *.list package picks
  setup/         # registry.conf and one-shot steps
  espanso/       # private Espanso matches
  profiles/      # host or role profiles
  docs/          # private notes (never published)
```

## Quick start

Put your files straight into this directory, or keep the overlay in its own repository elsewhere and point to it:

```bash
git clone git@example.com:you/dotfiles-private.git "$HOME/src/dotfiles-private"
export DOTFILES_PRIVATE="$HOME/src/dotfiles-private"
```

Pointing `DOTFILES_PRIVATE` elsewhere is the recommended setup when the overlay has its own git history: a repository cannot live in this directory without seeing these two tracked documents as foreign files.

See [private-overlay.md](private-overlay.md) for the full contract and which milestones wire each hook.
