#!/usr/bin/env bash
# Health checks: prerequisites, links, packages, identity.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/package-lists.sh
source "${BASH_SOURCE[0]%/*}/package-lists.sh"
# shellcheck source=lib/status.sh
source "${BASH_SOURCE[0]%/*}/status.sh"
# shellcheck source=lib/aur-packages.sh
source "${BASH_SOURCE[0]%/*}/aur-packages.sh"

_doctor_prerequisites() {
    local cmd missing=0
    for cmd in git curl zsh; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf 'prerequisites: ok (%s)\n' "$cmd"
        else
            printf 'prerequisites: missing %s\n' "$cmd"
            missing=1
        fi
    done
    if [ -z "$(_get_aur_helper)" ]; then
        printf 'prerequisites: missing AUR helper (yay or paru)\n'
        missing=1
    else
        printf 'prerequisites: ok (AUR helper)\n'
    fi
    return "$missing"
}

_doctor_links() {
    local target fail_count=0
    _load_link_entries all || return 1
    for target in "${_link_targets[@]}"; do
        if ! _check_link "$HOME/$target" "${_link_sources[$target]}" >/dev/null; then
            printf 'links: broken %s\n' "$target"
            fail_count=1
        fi
    done
    if [ "$fail_count" -eq 0 ]; then
        printf 'links: ok\n'
    fi
    return "$fail_count"
}

_doctor_packages() {
    local pack missing=0
    if [ "${DOTFILES_DOCTOR_SKIP_PACKAGES:-0}" = 1 ]; then
        printf 'packages: skipped\n'
        return 0
    fi
    while IFS= read -r pack || [ -n "$pack" ]; do
        [ -n "$pack" ] || continue
        if ! pacman -Q "$pack" &>/dev/null; then
            printf 'packages: missing %s\n' "$pack"
            missing=1
        fi
    done < <(_package_list pacman)
    if [ "$missing" -eq 0 ]; then
        printf 'packages: ok\n'
    fi
    return "$missing"
}

_doctor_identity() {
    local git_local="$HOME/.gitconfig.local" name email
    name="$(git config --file "$git_local" --get user.name 2>/dev/null || true)"
    email="$(git config --file "$git_local" --get user.email 2>/dev/null || true)"
    if [ -n "$name" ] && [ -n "$email" ]; then
        printf 'identity: ok\n'
        return 0
    fi
    printf 'identity: missing name or email in ~/.gitconfig.local\n'
    return 1
}

_doctor() {
    local fail_count=0
    e_header "dotfiles doctor"
    _doctor_prerequisites || fail_count=1
    _doctor_links || fail_count=1
    _doctor_packages || fail_count=1
    _doctor_identity || fail_count=1
    if [ "$fail_count" -eq 0 ]; then
        e_success "doctor: all checks passed"
    else
        e_error "doctor: one or more checks failed"
    fi
    return "$fail_count"
}
