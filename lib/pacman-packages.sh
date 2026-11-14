#!/usr/bin/env bash
# Pacman package installer. Honors DOTFILES_DRY_RUN, DOTFILES_YES.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"
# shellcheck source=lib/package-lists.sh
source "${BASH_SOURCE[0]%/*}/package-lists.sh"

_pacman_run() {
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi
    # shellcheck disable=SC2068
    sudo "$@"
}

# _pacman_packages [names...]
# When no names are given, installs every name from the pacman list.
_pacman_packages() {
    local packages_to_install="$1"
    local -a _packages=() to_install=() failed=()
    local pack

    if [ -z "$packages_to_install" ]; then
        packages_to_install="$(_package_list pacman | tr '\n' ' ')"
    fi
    # shellcheck disable=SC2206
    _packages=($packages_to_install)

    if [ "${#_packages[@]}" -eq 0 ]; then
        e_warning "No pacman packages selected"
        return 0
    fi

    e_info "Selected pacman packages: ${_packages[*]}"

    for pack in "${_packages[@]}"; do
        if pacman -Q "$pack" &>/dev/null; then
            e_arrow "Skipping installed package: $pack"
            continue
        fi
        to_install+=("$pack")
    done

    if [ "${#to_install[@]}" -eq 0 ]; then
        e_success "All selected pacman packages are already installed"
        return 0
    fi

    for pack in "${to_install[@]}"; do
        e_info "Installing $pack"
        if ! _pacman_run pacman -S --noconfirm --needed "$pack"; then
            e_error "Failed to install $pack"
            failed+=("$pack")
            continue
        fi
    done

    if [ "${#failed[@]}" -gt 0 ]; then
        e_error "Failed pacman packages: ${failed[*]}"
        return 1
    fi
    return 0
}

# _pacman_remove <names...>
_pacman_remove() {
    local -a _packages=("$@")
    local pack
    if [ "${#_packages[@]}" -eq 0 ]; then
        e_error "pacman:remove needs at least one package name"
        return 1
    fi
    _confirm "Remove pacman packages: ${_packages[*]}?" || return 1
    for pack in "${_packages[@]}"; do
        e_info "Removing $pack"
        if ! _pacman_run pacman -R --noconfirm "$pack"; then
            e_error "Failed to remove $pack"
            return 1
        fi
    done
}
