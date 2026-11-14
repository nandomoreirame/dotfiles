#!/usr/bin/env bash
# Write local git identity to ~/.gitconfig.local (never into the repo).

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"

_dotfiles_init() {
    local git_local="$HOME/.gitconfig.local"
    local name email existing_name existing_email

    existing_name="$(git config --file "$git_local" --get user.name 2>/dev/null || true)"
    existing_email="$(git config --file "$git_local" --get user.email 2>/dev/null || true)"

    if [ -n "$existing_name" ] || [ -n "$existing_email" ]; then
        e_info "Existing identity: ${existing_name:-?} <${existing_email:-?}>"
        if ! _confirm "Replace existing git identity?"; then
            e_arrow "Keeping existing ~/.gitconfig.local"
            return 0
        fi
    fi

    if ! _prompt_available; then
        e_error "No terminal input for init; set DOTFILES_PROMPT_STDIN=1 or DOTFILES_YES=1"
        return 1
    fi

    printf 'Full name [%s]: ' "${existing_name}" >&2
    IFS= read -r name || return 1
    [ -n "$name" ] || name="$existing_name"
    [ -n "$name" ] || { e_error "Name is required"; return 1; }

    printf 'Email [%s]: ' "${existing_email}" >&2
    IFS= read -r email || return 1
    [ -n "$email" ] || email="$existing_email"
    case "$email" in
        *@*.*) ;;
        *)
            e_error "Email must contain @ and a dot"
            return 1
            ;;
    esac

    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] git config --file %s user.name %s\n' "$git_local" "$name"
        printf '[dry-run] git config --file %s user.email %s\n' "$git_local" "$email"
        return 0
    fi

    git config --file "$git_local" user.name "$name"
    git config --file "$git_local" user.email "$email"
    e_success "Wrote identity to $git_local"
}
