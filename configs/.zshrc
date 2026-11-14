# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Prefer an exported DOTFILES; otherwise .zshenv already set it.
: "${DOTFILES:=${${(%):-%N}:A:h:h}}"
export DOTFILES

# Custom directory lives in this clone (plugins/themes come from Arch packages).
export ZSH_CUSTOM="${ZSH_CUSTOM:-$DOTFILES/.oh-my-zsh/custom}"

# Load shared bash settings when present (PATH extras, mise, zoxide).
[[ -r "$HOME/.bashrc" ]] && . "$HOME/.bashrc"

# Prevent "Insecure completion-dependent directories detected" warning
# This must be set BEFORE oh-my-zsh is loaded
ZSH_DISABLE_COMPFIX=true

# Load ZSH options (ZSH_THEME, plugins, etc.) BEFORE oh-my-zsh so plugins load correctly
[[ -r "$ZSH_CUSTOM/options.zsh" ]] && source "$ZSH_CUSTOM/options.zsh"

# Load Oh My Zsh when installed (typically ~/.oh-my-zsh from the verified installer)
if [[ -n "${ZSH:-}" && -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Third-party plugins and theme from Arch packages (skip silently when absent)
[[ -r /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]] && source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Private overlay: source private/shell/*.zsh in name order when present
if [[ -r "$DOTFILES/lib/private.sh" ]]; then
  source "$DOTFILES/lib/private.sh"
  if _private_has shell; then
    for _private_shell_file in "$(_private_path shell)"/*.zsh(N); do
      source "$_private_shell_file"
    done
    unset _private_shell_file
  fi
fi

# Optional WordPress completion helper
[[ -r "$DOTFILES/lib/wp-completion.sh" ]] && source "$DOTFILES/lib/wp-completion.sh"

# Load profile configuration when present
if [[ -r "$DOTFILES/lib/profiles.sh" ]]; then
  source "$DOTFILES/lib/profiles.sh"
  if typeset -f profile_load >/dev/null 2>&1; then
    profile_load
  fi
fi

# Optional AWS credentials file in the home directory (never committed)
if [[ -f "$HOME/.aws-credentials" && -s "$HOME/.aws-credentials" && $- == *i* ]]; then
  source "$HOME/.aws-credentials"
fi
alias load-aws='[ -f ~/.aws-credentials ] && source ~/.aws-credentials && echo "AWS credentials loaded"'
alias unload-aws='unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN && echo "AWS credentials cleared"'
alias show-aws='[ -n "$AWS_ACCESS_KEY_ID" ] && echo "AWS credentials are loaded" || echo "AWS credentials are not loaded"'

# pnpm (PATH entry lives in .zshenv)
export PNPM_HOME="$HOME/.local/share/pnpm"

# Podman / Docker compatibility
# Point Docker-API tooling (Testcontainers, lazydocker, IDE extensions) at the
# rootless podman socket. Requires: systemctl --user enable --now podman.socket
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"

# sharp (npm): pacman's libvips makes sharp build from source against it and
# fail ("Please add node-addon-api"). Use sharp's own prebuilt binary instead.
export SHARP_IGNORE_GLOBAL_LIBVIPS=1

# fzf palette (bg:-1 keeps the terminal background)
export FZF_DEFAULT_OPTS="--color=bg:-1,fg:#F4F4F5,hl:#F5A623,bg+:#18181B,fg+:#F4F4F5,hl+:#F5A623,gutter:-1,info:#A1A1AA,prompt:#F5A623,pointer:#F5A623,marker:#34D399,spinner:#F5A623,header:#A1A1AA,border:#3F3F46,separator:#3F3F46,scrollbar:#3F3F46,query:#F4F4F5"

fpath=("$HOME/.zfunctions" $fpath)
fpath=("/usr/local/share/zsh-completions" $fpath)

export CARGO_HOME="$HOME/.cargo"
[[ "$TERM_PROGRAM" == "cursor" ]] && unset ARGV0

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Re-assert uniqueness after anything sourced above may have touched PATH.
typeset -U path
path=($path)

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Optional grok completions
[[ -d "$HOME/.grok/completions/zsh" ]] && fpath=("$HOME/.grok/completions/zsh" $fpath)
