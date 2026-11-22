#!/usr/bin/env bash
# Pacman package installer. Honors DOTFILES_DRY_RUN, DOTFILES_YES.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/spinner.sh
source "${BASH_SOURCE[0]%/*}/spinner.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"
# shellcheck source=lib/package-lists.sh
source "${BASH_SOURCE[0]%/*}/package-lists.sh"

_pacman_run() {
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi
    spin_sudo_prime
    spin_run "${SPIN_MSG:-$*}" sudo "$@"
}

# _pacman_packages [names...]
# When no names are given, installs every name from the pacman list.
_pacman_packages() {
    local packages_to_install="$1"
    local -a _packages=() to_install=() failed_pkgs=()
    local pack

    if [ -z "$packages_to_install" ]; then
        packages_to_install="$(_package_list pacman | tr '\n' ' ')" || return 1
    fi
    read -ra _packages <<< "$packages_to_install"

    if [ "${#_packages[@]}" -eq 0 ]; then
        e_warning "No pacman packages selected"
        return 0
    fi

    for pack in "${_packages[@]}"; do
        if ! _package_name_valid "$pack"; then
            e_error "Invalid package name: $pack"
            return 1
        fi
    done

    e_info "Selected pacman packages: ${_packages[*]}"

    for pack in "${_packages[@]}"; do
        if pacman -Q -- "$pack" &>/dev/null; then
            e_arrow "Skipping installed package: $pack"
            continue
        fi
        to_install+=("$pack")
    done

    if [ "${#to_install[@]}" -eq 0 ]; then
        e_success "All selected pacman packages are already installed"
        return 0
    fi

    # Arch does not support partial upgrades: sync and upgrade once, and only
    # when something is missing, before installing the new packages.
    if ! SPIN_MSG="Syncing and upgrading the system" _pacman_run pacman -Syu --noconfirm; then
        e_error "System upgrade failed; no package was installed"
        return 1
    fi

    for pack in "${to_install[@]}"; do
        if ! SPIN_MSG="Installing $pack" _pacman_run pacman -S --noconfirm --needed -- "$pack"; then
            e_error "Failed to install $pack"
            failed_pkgs+=("$pack")
            continue
        fi
    done

    if [ "${#failed_pkgs[@]}" -gt 0 ]; then
        e_error "Failed pacman packages: ${failed_pkgs[*]}"
        return 1
    fi
    return 0
}

# _pacman_remove <names...>
_pacman_remove() {
    local -a _packages=("$@")
    local pack
    if [ "${#_packages[@]}" -eq 0 ]; then
        e_error "packages remove needs at least one package name"
        return 1
    fi
    for pack in "${_packages[@]}"; do
        if ! _package_name_valid "$pack"; then
            e_error "Invalid package name: $pack"
            return 1
        fi
    done
    _confirm "Remove pacman packages: ${_packages[*]}?" || return 1
    for pack in "${_packages[@]}"; do
        if ! SPIN_MSG="Removing $pack" _pacman_run pacman -R --noconfirm -- "$pack"; then
            e_error "Failed to remove $pack"
            return 1
        fi
    done
}
