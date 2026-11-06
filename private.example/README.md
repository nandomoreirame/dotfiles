# Private overlay example

Copy this directory (or clone your real private repo) to the path in `DOTFILES_PRIVATE` (default: `$DOTFILES/private`). A missing overlay is never an error.

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

```bash
# from the public repo root
cp -a private.example "$DOTFILES_PRIVATE"
# or:
# git clone git@example.com:you/dotfiles-private.git "$DOTFILES_PRIVATE"
```

Override the location when needed:

```bash
export DOTFILES_PRIVATE="$HOME/src/dotfiles-private"
```

See `docs/private-overlay.md` in the public repository for the full contract and which milestones wire each hook.
