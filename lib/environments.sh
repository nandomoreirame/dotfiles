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
mkdir -p "$TMP_DIR"

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

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

purple=$(tput setaf 171)
red=$(tput setaf 1)
green=$(tput setaf 76)
tan=$(tput setaf 3)
blue=$(tput setaf 38)


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
