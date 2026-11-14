#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

_help() {
    if [ "${1:-}" = -l ]; then
        printf '%s\n' 'Usage: dotfiles links [--all|--files|--paths|--help]' \
            '  --all    Create every configured symbolic link' \
            '  --files  Link the [files] entries' \
            '  --paths  Link the [paths] entries (and [paths:arch] on Arch)' \
            'Conflicting files are backed up. DOTFILES_YES=1 skips confirmations.'
        return
    fi
    printf '%s\n' 'Usage: dotfiles <command>' \
        '  links              Manage configured symbolic links' \
        '  pacman:install     Install Arch packages from packages/pacman.list' \
        '  pacman:remove      Remove Arch packages (names required)' \
        '  aur:install        Install AUR packages from packages/aur.list' \
        '  aur:remove         Remove AUR packages (names required)' \
        '  flatpak:install    Install Flatpak apps from packages/flatpak.list' \
        '  flatpak:remove     Remove Flatpak apps (names required)' \
        '  node:install       Install global npm packages from packages/node.list' \
        '  node:remove        Remove global npm packages (names required)' \
        '  sh:install         Install shell apps (ohmyzsh, mise, docker)' \
        '  langs:install      Install languages from configs/mise/config.toml' \
        '  fonts:install      Install the pacman fonts group' \
        '  apps:install       Run pacman, AUR, Flatpak, Node, sh and langs' \
        '  setup              Run auto setup scripts from the registry' \
        '  setup:run          Run one setup script by name' \
        '  init               Write local git identity to ~/.gitconfig.local' \
        '  doctor             Check prerequisites, links, packages and identity' \
        '  --status           Check links, PATH and environment variables' \
        '  --verify           Verify every configured link' \
        '  --help, -h         Show this help' \
        '  --version, -v      Print the version' \
        '' \
        'Shared install flags: --dry-run --yes --no-remote --group <name> --only <names>' \
        'Interactive menus are not available in this version.' \
        'Use dotfiles links --help for link options.'
}
