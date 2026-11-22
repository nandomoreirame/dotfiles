#!/usr/bin/env bash
# Package removal entry points. Names are required; confirmation via _confirm.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/pacman-packages.sh
source "${BASH_SOURCE[0]%/*}/pacman-packages.sh"
# shellcheck source=lib/aur-packages.sh
source "${BASH_SOURCE[0]%/*}/aur-packages.sh"
# shellcheck source=lib/flatpak-packages.sh
source "${BASH_SOURCE[0]%/*}/flatpak-packages.sh"
# shellcheck source=lib/node-packages.sh
source "${BASH_SOURCE[0]%/*}/node-packages.sh"

_remove_require_names() {
    local kind="$1"
    shift
    if [ "$#" -eq 0 ]; then
        e_error "packages remove needs at least one package name ($kind)"
        return 1
    fi
    return 0
}

_remove_pacman() {
    _remove_require_names pacman "$@" || return 1
    _pacman_remove "$@"
}

_remove_aur() {
    _remove_require_names aur "$@" || return 1
    _aur_remove "$@"
}

_remove_flatpak() {
    _remove_require_names flatpak "$@" || return 1
    _flatpak_remove "$@"
}

_remove_node() {
    _remove_require_names node "$@" || return 1
    _node_remove "$@"
}
