#!/usr/bin/env bash
# Global npm package installer. Honors DOTFILES_DRY_RUN, DOTFILES_YES.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"
# shellcheck source=lib/package-lists.sh
source "${BASH_SOURCE[0]%/*}/package-lists.sh"

_node_run() {
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

_node_is_installed() {
    local package="$1"
    npm list -g --depth=0 "$package" 2>/dev/null | grep -q "$package"
}

# _node_packages [names...]
_node_packages() {
    local packages_to_install="$1"
    local package
    local -a _packages=() failed_pkgs=()

    if ! command -v npm >/dev/null 2>&1; then
        e_error "npm not found; install Node.js first (mise or pacman)"
        return 1
    fi

    if [ -z "$packages_to_install" ]; then
        packages_to_install="$(_package_list node | tr '\n' ' ')" || return 1
    fi
    read -ra _packages <<< "$packages_to_install"

    if [ "${#_packages[@]}" -eq 0 ]; then
        e_warning "No npm packages selected"
        return 0
    fi

    for package in "${_packages[@]}"; do
        if ! _package_name_valid "$package"; then
            e_error "Invalid package name: $package"
            return 1
        fi
    done

    e_info "Selected npm packages: ${_packages[*]}"

    for package in "${_packages[@]}"; do
        if _node_is_installed "$package"; then
            e_arrow "Skipping installed package: $package"
            continue
        fi
        e_info "Installing $package"
        if ! _node_run npm install -g -- "$package"; then
            e_error "Failed to install $package"
            failed_pkgs+=("$package")
            continue
        fi
    done

    if [ "${#failed_pkgs[@]}" -gt 0 ]; then
        e_error "Failed npm packages: ${failed_pkgs[*]}"
        return 1
    fi
    return 0
}

# _node_remove <names...>
_node_remove() {
    local -a _packages=("$@")
    local package
    if [ "${#_packages[@]}" -eq 0 ]; then
        e_error "node:remove needs at least one package name"
        return 1
    fi
    if ! command -v npm >/dev/null 2>&1; then
        e_error "npm not found"
        return 1
    fi
    for package in "${_packages[@]}"; do
        if ! _package_name_valid "$package"; then
            e_error "Invalid package name: $package"
            return 1
        fi
    done
    _confirm "Remove npm packages: ${_packages[*]}?" || return 1
    for package in "${_packages[@]}"; do
        e_info "Removing $package"
        if ! _node_run npm uninstall -g -- "$package"; then
            e_error "Failed to remove $package"
            return 1
        fi
    done
}
