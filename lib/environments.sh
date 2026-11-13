#!/usr/bin/env bash

# ============================================
# Central variables
# ============================================

export DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"
export ZSH_PLUGINS="$ZSH_CUSTOM/plugins"
export ZSH_THEMES="$ZSH_CUSTOM/themes"
export TMP_DIR="$DOTFILES/.tmp"

# ============================================
# Set Colors
# ============================================

export bold
export underline
export reset
export purple
export red
export green
export tan
export blue

bold='' underline='' reset='' purple='' red='' green='' tan='' blue=''
if [ -n "${TERM:-}" ] && [ "$TERM" != dumb ] && command -v tput >/dev/null 2>&1; then
    bold=$(tput bold 2>/dev/null) || bold=''
    underline=$(tput smul 2>/dev/null) || underline=''
    reset=$(tput sgr0 2>/dev/null) || reset=''
    purple=$(tput setaf 171 2>/dev/null) || purple=''
    red=$(tput setaf 1 2>/dev/null) || red=''
    green=$(tput setaf 76 2>/dev/null) || green=''
    tan=$(tput setaf 3 2>/dev/null) || tan=''
    blue=$(tput setaf 38 2>/dev/null) || blue=''
fi

# ============================================
# Operating system detection
# ============================================

_dotfiles_detect_os() {
    local uname_out
    uname_out=$(uname -s 2>/dev/null || echo "unknown")

    case "$uname_out" in
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

DOTFILES_OS="$(_dotfiles_detect_os)"
export DOTFILES_OS
export DOTFILES_IS_LINUX=false

case "$DOTFILES_OS" in
    linux)
        DOTFILES_IS_LINUX=true
        ;;
esac

# ============================================
# Arch Linux detection
# ============================================

export DOTFILES_IS_ARCH=false

if [ "${DOTFILES_IS_LINUX:-false}" = "true" ]; then
    _os_release_file="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"
    if [ -f "$_os_release_file" ]; then
        _os_id=$(grep -E '^ID=' "$_os_release_file" 2>/dev/null | cut -d= -f2 | tr -d '"') || true
        _os_id_like=$(grep -E '^ID_LIKE=' "$_os_release_file" 2>/dev/null | cut -d= -f2 | tr -d '"') || true

        if [ "$_os_id" = "arch" ] || echo "$_os_id_like" | grep -q "arch"; then
            DOTFILES_IS_ARCH=true
        fi
    fi
fi

unset -f _dotfiles_detect_os
