#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/links.sh
source "${BASH_SOURCE[0]%/*}/links.sh"

_check_link() {
    local target="$1" expected="$2"
    if [ ! -L "$target" ]; then
        printf 'Missing or non-symbolic link: %s\n' "$target"
        return 1
    fi
    if [ ! -e "$target" ]; then
        printf 'Broken link: %s\n' "$target"
        return 1
    fi
    if [ "$(realpath -- "$target")" != "$(realpath -- "$expected")" ]; then
        printf 'Foreign link: %s\n' "$target"
        return 1
    fi
    printf 'ok: %s\n' "$target"
}

_verify() {
    local target failed=0 total=0
    _load_link_entries all || return 1
    for target in "${_link_targets[@]}"; do
        total=$((total + 1))
        if ! _check_link "$HOME/$target" "${_link_sources[$target]}"; then
            failed=$((failed + 1))
        fi
    done
    printf 'Links: %d checked, %d failed\n' "$total" "$failed"
    [ "$failed" -eq 0 ]
}

_check_scripts() {
    local directory failed=0
    for directory in "$DOTFILES/bin" "$DOTFILES"/bin/*; do
        [ -d "$directory" ] || continue
        case ":${PATH:-}:" in
            *":$directory:"*) printf 'ok: PATH contains %s\n' "$directory" ;;
            *) printf 'Missing PATH entry: %s\n' "$directory"; failed=1 ;;
        esac
    done
    return "$failed"
}

_check_environment() {
    local name failed=0
    for name in DOTFILES HOME; do
        if [ -n "${!name}" ] && [ -d "${!name}" ]; then
            printf 'ok: %s\n' "$name"
        else
            printf 'Invalid environment: %s\n' "$name"
            failed=1
        fi
    done
    return "$failed"
}

_status() {
    local failed=0
    printf '%s\n' 'Dotfiles Status' 'Links'
    _verify || failed=1
    printf '%s\n' 'PATH'
    _check_scripts || failed=1
    printf '%s\n' 'Environment'
    _check_environment || failed=1
    printf 'Status: %s\n' "$([ "$failed" -eq 0 ] && printf ok || printf failed)"
    return "$failed"
}
