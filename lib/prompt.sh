#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# DOTFILES_PROMPT_STDIN=1 explicitly permits scripted answers over stdin.
_prompt_available() {
    if [ -t 0 ] || [ "${DOTFILES_PROMPT_STDIN:-0}" = 1 ]; then
        return 0
    fi
    printf '%s\n' 'No terminal input; use --yes for automatic answers.' >&2
    return 1
}

_confirm() {
    [ "$#" -ge 1 ] && [ "$#" -le 2 ] || return 1
    local answer default="${2:-no}"
    case "$default" in yes|no) ;; *) return 1 ;; esac
    [ "${DOTFILES_YES:-0}" != 1 ] || return 0
    _prompt_available || return 1
    printf '%s [%s]: ' "$1" "$default" >&2
    IFS= read -r answer || return 1
    answer="${answer,,}"
    [ -n "$answer" ] || answer="$default"
    case "$answer" in y|yes) return 0 ;; *) return 1 ;; esac
}

_choose() {
    [ "$#" -ge 2 ] || return 1
    local title="$1" answer item index=0
    shift
    if [ "${DOTFILES_YES:-0}" = 1 ]; then
        printf '%s\n' "$1"
        return 0
    fi
    _prompt_available || return 1
    printf '%s\n' "$title" >&2
    for item in "$@"; do
        index=$((index + 1))
        printf '%d) %s\n' "$index" "$item" >&2
    done
    IFS= read -r answer || return 1
    # Compare strings to bounded indices, avoiding arithmetic on untrusted input.
    index=0
    for item in "$@"; do
        index=$((index + 1))
        if [ "$answer" = "$index" ]; then
            printf '%s\n' "$item"
            return 0
        fi
    done
    return 1
}
