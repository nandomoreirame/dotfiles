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
        '  links       Manage configured symbolic links' \
        '  --status    Check links, PATH and environment variables' \
        '  --verify    Verify every configured link' \
        '  --help, -h  Show this help' \
        '  --version, -v  Print the version' \
        'Use dotfiles links --help for link options.'
}
