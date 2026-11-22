#!/usr/bin/env bash
# Install orchestration for package kinds and shell apps.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/package-lists.sh
source "${BASH_SOURCE[0]%/*}/package-lists.sh"
# shellcheck source=lib/pacman-packages.sh
source "${BASH_SOURCE[0]%/*}/pacman-packages.sh"
# shellcheck source=lib/aur-packages.sh
source "${BASH_SOURCE[0]%/*}/aur-packages.sh"
# shellcheck source=lib/flatpak-packages.sh
source "${BASH_SOURCE[0]%/*}/flatpak-packages.sh"
# shellcheck source=lib/node-packages.sh
source "${BASH_SOURCE[0]%/*}/node-packages.sh"
# shellcheck source=lib/sh-apps.sh
source "${BASH_SOURCE[0]%/*}/sh-apps.sh"
# shellcheck source=lib/fonts.sh
source "${BASH_SOURCE[0]%/*}/fonts.sh"
# shellcheck source=lib/mise-packages.sh
source "${BASH_SOURCE[0]%/*}/mise-packages.sh"

# Resolve package names from explicit names, --group or the full list.
_apps_resolve_names() {
    local kind="$1"
    local group="${2:-}"
    local only="${3:-}"
    if [ -n "$only" ]; then
        printf '%s\n' "$only"
        return 0
    fi
    if [ -n "$group" ]; then
        _package_list "$kind" "$group" | tr '\n' ' '
        return 0
    fi
    _package_list "$kind" | tr '\n' ' '
}

_apps_install_pacman() {
    local group="${1:-}" only="${2:-}" names
    names="$(_apps_resolve_names pacman "$group" "$only")"
    _pacman_packages "$names"
}

_apps_install_aur() {
    local group="${1:-}" only="${2:-}" names
    names="$(_apps_resolve_names aur "$group" "$only")"
    _aur_packages "$names"
}

_apps_install_flatpak() {
    local group="${1:-}" only="${2:-}" names
    names="$(_apps_resolve_names flatpak "$group" "$only")"
    _flatpak_packages "$names"
}

_apps_install_node() {
    local group="${1:-}" only="${2:-}" names
    names="$(_apps_resolve_names node "$group" "$only")"
    _node_packages "$names"
}

_apps_install_sh() {
    local only="${2:-}"
    if [ -n "$only" ]; then
        _sh_apps "$only"
    else
        _sh_apps ""
    fi
}

_apps_install_langs() {
    _install_mise_packages
}

_apps_install_fonts() {
    _install_fonts
}

# `packages install` without --manager runs pacman, AUR, Flatpak, Node, sh and langs.
_apps_install_all() {
    local group="${1:-}" only="${2:-}"
    local fail_count=0
    _apps_install_pacman "$group" "$only" || fail_count=1
    _apps_install_aur "$group" "$only" || fail_count=1
    _apps_install_flatpak "$group" "$only" || fail_count=1
    _apps_install_node "$group" "$only" || fail_count=1
    _apps_install_sh "$group" "$only" || fail_count=1
    _apps_install_langs || fail_count=1
    return "$fail_count"
}
