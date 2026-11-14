# ~/.bashrc: interactive bash settings for this clone.

if [[ -n "$BASH_VERSION" ]]; then
  # Prefer an exported DOTFILES; otherwise derive it from this file (follows symlinks).
  if [[ -z "${DOTFILES:-}" ]]; then
    _bashrc_src="${BASH_SOURCE[0]:-$0}"
    if command -v readlink >/dev/null 2>&1; then
      _bashrc_src="$(readlink -f "$_bashrc_src" 2>/dev/null || printf '%s' "$_bashrc_src")"
    fi
    DOTFILES="$(cd "$(dirname "$_bashrc_src")/.." && pwd)"
    unset _bashrc_src
  fi
  export DOTFILES

  if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate bash)"
  elif command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
  fi

  [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

  export PATH="$HOME/.local/bin:$PATH"
  export PATH="$PATH:$DOTFILES/bin/git"
  export PATH="$PATH:$DOTFILES/bin/sys"
  export PATH="$PATH:$DOTFILES/bin/utils"
  export PATH="$PATH:$DOTFILES/bin"

  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
  fi
fi
