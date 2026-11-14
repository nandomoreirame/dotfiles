#!/usr/bin/env bash
# Opt-in Git hooks: toggle core.hooksPath in ~/.gitconfig.local.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"

_HOOKS_GIT_LOCAL="${HOME}/.gitconfig.local"
_HOOKS_PATH="${DOTFILES}/git-hooks"

_hooks_git_local_ensure() {
    touch "$_HOOKS_GIT_LOCAL"
}

_hooks_enable() {
    local want_strip=0 arg
    for arg in "$@"; do
        case "$arg" in
            guard) ;;
            strip) want_strip=1 ;;
            *)
                printf 'Error: unknown hooks enable option: %s\n' "$arg" >&2
                printf 'Usage: dotfiles hooks enable [guard] [strip]\n' >&2
                return 1
                ;;
        esac
    done

    if ! _confirm "Enable Git hooks for every repository on this machine?"; then
        printf 'hooks enable cancelled\n'
        return 1
    fi

    _hooks_git_local_ensure
    git config --file "$_HOOKS_GIT_LOCAL" core.hooksPath "$_HOOKS_PATH"
    if [ "$want_strip" -eq 1 ]; then
        git config --file "$_HOOKS_GIT_LOCAL" dotfiles.hookStrip true
    else
        git config --file "$_HOOKS_GIT_LOCAL" --unset dotfiles.hookStrip 2>/dev/null || true
    fi

    printf 'Enabled Git hooks at %s\n' "$_HOOKS_PATH"
    printf 'Warning: every repository on this machine will use these hooks.\n'
    printf 'Undo with: dotfiles hooks disable\n'
}

_hooks_disable() {
    _hooks_git_local_ensure
    git config --file "$_HOOKS_GIT_LOCAL" --unset core.hooksPath 2>/dev/null || true
    git config --file "$_HOOKS_GIT_LOCAL" --unset dotfiles.hookStrip 2>/dev/null || true
    printf 'hooks disabled\n'
}

_hooks_status() {
    local path strip guard_state strip_state
    path="$(git config --file "$_HOOKS_GIT_LOCAL" --get core.hooksPath 2>/dev/null || true)"
    strip="$(git config --file "$_HOOKS_GIT_LOCAL" --get dotfiles.hookStrip 2>/dev/null || true)"

    if [ -n "$path" ]; then
        guard_state=on
    else
        guard_state=off
    fi
    if [ "$strip" = "true" ]; then
        strip_state=on
    else
        strip_state=off
    fi

    if [ "$guard_state" = "off" ]; then
        printf 'hooks: disabled\n'
    fi
    printf 'guard: %s\n' "$guard_state"
    printf 'strip: %s\n' "$strip_state"
    if [ -n "$path" ]; then
        printf 'path: %s\n' "$path"
    fi
}
