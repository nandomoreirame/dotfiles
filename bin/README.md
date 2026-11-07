# Helper scripts

Optional helpers under `bin/sys/` and `bin/utils/`. Nothing here is required by the rest of the repository; each script is standalone and covered by its own BATS file.

## PATH

Add the helper directories to your PATH (replace the clone path as needed):

```bash
export PATH="$PATH:/path/to/dotfiles/bin/sys:/path/to/dotfiles/bin/utils"
# or, when DOTFILES points at the clone:
export PATH="$PATH:$DOTFILES/bin/sys:$DOTFILES/bin/utils"
```

## Helpers

| Helper | Purpose | Usage | Needs | Privileges |
|---|---|---|---|---|
