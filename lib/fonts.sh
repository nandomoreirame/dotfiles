#!/usr/bin/env bash
# Install fonts from the pacman fonts group. No downloads, no deletions.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/pacman-packages.sh
source "${BASH_SOURCE[0]%/*}/pacman-packages.sh"

_install_fonts() {
    local packages
    packages="$(_package_list pacman fonts | tr '\n' ' ')"
    _pacman_packages "$packages"
}
