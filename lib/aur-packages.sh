#!/usr/bin/env bash
# AUR package installer (yay or paru). Honors DOTFILES_DRY_RUN, DOTFILES_YES.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"
# shellcheck source=lib/package-lists.sh
source "${BASH_SOURCE[0]%/*}/package-lists.sh"

_get_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        printf '%s\n' "yay"
    elif command -v paru >/dev/null 2>&1; then
        printf '%s\n' "paru"
    else
        printf '%s\n' ""
    fi
}

_aur_run() {
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

# _aur_packages [names...]
_aur_packages() {
    local packages_to_install="$1"
    local aur_helper pack
    local -a _packages=() failed_pkgs=()

    aur_helper="$(_get_aur_helper)"
    if [ -z "$aur_helper" ]; then
        e_error "No AUR helper found (yay or paru)"
        e_info "Install one first:"
        e_info "  git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si"
        e_info "  git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si"
        return 1
    fi

    if [ -z "$packages_to_install" ]; then
        packages_to_install="$(_package_list aur | tr '\n' ' ')"
    fi
    # shellcheck disable=SC2206
    _packages=($packages_to_install)

    if [ "${#_packages[@]}" -eq 0 ]; then
        e_warning "No AUR packages selected"
        return 0
    fi

    e_info "Selected AUR packages: ${_packages[*]}"
    e_info "Using AUR helper: $aur_helper"

    for pack in "${_packages[@]}"; do
        if pacman -Q "$pack" &>/dev/null; then
            e_arrow "Skipping installed package: $pack"
            continue
        fi
        e_info "Installing AUR: $pack"
        if ! _aur_run "$aur_helper" -S --noconfirm --needed "$pack"; then
            e_error "Failed to install $pack"
            failed_pkgs+=("$pack")
            continue
        fi
    done

    if [ "${#failed_pkgs[@]}" -gt 0 ]; then
        e_error "Failed AUR packages: ${failed_pkgs[*]}"
        return 1
    fi
    return 0
}

# _aur_remove <names...>
_aur_remove() {
    local -a _packages=("$@")
    local pack aur_helper
    if [ "${#_packages[@]}" -eq 0 ]; then
        e_error "aur:remove needs at least one package name"
        return 1
    fi
    aur_helper="$(_get_aur_helper)"
    if [ -z "$aur_helper" ]; then
        e_error "No AUR helper found (yay or paru)"
        return 1
    fi
    _confirm "Remove AUR packages: ${_packages[*]}?" || return 1
    for pack in "${_packages[@]}"; do
        e_info "Removing $pack"
        if ! _aur_run "$aur_helper" -R --noconfirm "$pack"; then
            e_error "Failed to remove $pack"
            return 1
        fi
    done
}
