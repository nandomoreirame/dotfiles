#!/usr/bin/env bash
# Flatpak package installer. Honors DOTFILES_DRY_RUN, DOTFILES_YES.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"
# shellcheck source=lib/package-lists.sh
source "${BASH_SOURCE[0]%/*}/package-lists.sh"

_flatpak_run() {
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

# _flatpak_packages [names...]
_flatpak_packages() {
    local packages_to_install="$1"
    local pack
    local -a _packages=() failed_pkgs=()

    if [ -z "$packages_to_install" ]; then
        packages_to_install="$(_package_list flatpak | tr '\n' ' ')"
    fi
    # shellcheck disable=SC2206
    _packages=($packages_to_install)

    if [ "${#_packages[@]}" -eq 0 ]; then
        e_warning "No Flatpak packages selected"
        return 0
    fi

    e_info "Selected Flatpak packages: ${_packages[*]}"

    for pack in "${_packages[@]}"; do
        if flatpak info "$pack" &>/dev/null; then
            e_arrow "Skipping installed package: $pack"
            continue
        fi
        e_info "Installing $pack"
        if ! _flatpak_run flatpak install -y flathub "$pack"; then
            e_error "Failed to install $pack"
            failed_pkgs+=("$pack")
            continue
        fi
    done

    if [ "${#failed_pkgs[@]}" -gt 0 ]; then
        e_error "Failed Flatpak packages: ${failed_pkgs[*]}"
        return 1
    fi
    return 0
}

# _flatpak_remove <names...>
_flatpak_remove() {
    local -a _packages=("$@")
    local pack
    if [ "${#_packages[@]}" -eq 0 ]; then
        e_error "flatpak:remove needs at least one package name"
        return 1
    fi
    _confirm "Remove Flatpak packages: ${_packages[*]}?" || return 1
    for pack in "${_packages[@]}"; do
        e_info "Removing $pack"
        if ! _flatpak_run flatpak uninstall -y "$pack"; then
            e_error "Failed to remove $pack"
            return 1
        fi
    done
}
