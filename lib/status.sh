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
    local target fail_count=0 total=0
    _load_link_entries all || return 1
    for target in "${_link_targets[@]}"; do
        total=$((total + 1))
        if ! _check_link "$HOME/$target" "${_link_sources[$target]}"; then
            fail_count=$((fail_count + 1))
        fi
    done
    printf 'Links: %d checked, %d failed\n' "$total" "$fail_count"
    [ "$fail_count" -eq 0 ]
}

_check_scripts() {
    local directory fail_count=0
    for directory in "$DOTFILES/bin" "$DOTFILES"/bin/*; do
        [ -d "$directory" ] || continue
        case ":${PATH:-}:" in
            *":$directory:"*) printf 'ok: PATH contains %s\n' "$directory" ;;
            *) printf 'Missing PATH entry: %s\n' "$directory"; fail_count=1 ;;
        esac
    done
    return "$fail_count"
}

_check_environment() {
    local name fail_count=0
    for name in DOTFILES HOME; do
        if [ -n "${!name}" ] && [ -d "${!name}" ]; then
            printf 'ok: %s\n' "$name"
        else
            printf 'Invalid environment: %s\n' "$name"
            fail_count=1
        fi
    done
    return "$fail_count"
}

_check_installed_packages() {
    # shellcheck source=lib/package-lists.sh
    source "${BASH_SOURCE[0]%/*}/package-lists.sh"
    local pack missing=0 total=0
    while IFS= read -r pack || [ -n "$pack" ]; do
        [ -n "$pack" ] || continue
        total=$((total + 1))
        if pacman -Q "$pack" &>/dev/null; then
            printf 'ok: package %s\n' "$pack"
        else
            printf 'Missing package: %s\n' "$pack"
            missing=$((missing + 1))
        fi
    done < <(_package_list pacman)
    printf 'Packages: %d checked, %d missing\n' "$total" "$missing"
    [ "$missing" -eq 0 ]
}

_check_profile() {
    local marker="${DOTFILES}/profiles/.current-git" current="" name=""
    printf 'Profile\n'
    if [ -f "$marker" ]; then
        current=$(tr -d '\n' < "$marker")
        name="${current#git-}"
        name="${name%.conf}"
    fi
    if [ -n "$name" ]; then
        printf 'ok: active identity %s\n' "$name"
        return 0
    fi
    printf 'No active identity profile\n'
    return 0
}

_status() {
    local fail_count=0
    printf '%s\n' 'Dotfiles Status' 'Links'
    _verify || fail_count=1
    printf '%s\n' 'PATH'
    _check_scripts || fail_count=1
    printf '%s\n' 'Environment'
    _check_environment || fail_count=1
    printf '%s\n' 'Packages'
    _check_installed_packages || fail_count=1
    _check_profile || fail_count=1
    printf 'Status: %s\n' "$([ "$fail_count" -eq 0 ] && printf ok || printf failed)"
    return "$fail_count"
}
