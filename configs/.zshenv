# .zshenv - always loaded by zsh (before .zshrc).
# Builds PATH once. Nothing here may print.

# Resolve the clone from this file's real path (follows the ~/.zshenv symlink).
# An exported DOTFILES wins so tests and overlays can override.
: "${DOTFILES:=${${(%):-%N}:A:h:h}}"
export DOTFILES

# mise directories (defaults match the Arch package layout)
export MISE_DATA_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}"
export MISE_CACHE_DIR="${MISE_CACHE_DIR:-$HOME/.cache/mise}"

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Single PATH source: unique entries, only directories that exist.
# Dotfiles bin dirs come last so system/mise tools win.
typeset -U path
_path_candidates=(
  "$HOME/.local/bin"
  "$MISE_DATA_DIR/shims"
  "$HOME/.local/share/pnpm"
  "$HOME/.cargo/bin"
  "$HOME/.opencode/bin"
  "$HOME/.grok/bin"
  "$HOME/.kimi-code/bin"
  "$HOME/.bun/bin"
  /usr/local/sbin
  /usr/local/bin
  /usr/bin
  "$HOME/.local/share/flatpak/exports/bin"
  /var/lib/flatpak/exports/bin
  /usr/bin/site_perl
  /usr/bin/vendor_perl
  /usr/bin/core_perl
  "$DOTFILES/private/bin"
  "$DOTFILES/bin/git"
  "$DOTFILES/bin/sys"
  "$DOTFILES/bin/utils"
  "$DOTFILES/bin"
)
path=()
for _d in $_path_candidates; do
  [[ -d $_d ]] && path+=("$_d")
done
unset _path_candidates _d
export PATH

# 1Password SSH agent
if [[ -S "$HOME/.1password/agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi
