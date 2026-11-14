#!/usr/bin/env bash
# New-machine entry point. Never pipes a download into a shell.
set -eo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

# shellcheck source=lib/environments.sh
source "$DOTFILES/lib/environments.sh"
# shellcheck source=lib/prompt.sh
source "$DOTFILES/lib/prompt.sh"
# shellcheck source=lib/install.sh
source "$DOTFILES/lib/install.sh"

usage() {
    printf '%s\n' \
        "Usage: ./install.sh [--dry-run] [--yes] [--no-remote] [--group <name>] [--help]" \
        "  --dry-run    Print steps without changing the system" \
        "  --yes        Accept every confirmation" \
        "  --no-remote  Skip verified remote downloads (oh-my-zsh)" \
        "  --group      Limit the package step to one pacman group" \
        "  --help       Show this help"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run) export DOTFILES_DRY_RUN=1; shift ;;
        --yes|-y) export DOTFILES_YES=1; shift ;;
        --no-remote) export DOTFILES_NO_REMOTE=1; shift ;;
        --group)
            [ "$#" -ge 2 ] || { printf 'Error: --group needs a value\n' >&2; exit 1; }
            export DOTFILES_INSTALL_GROUP="$2"
            shift 2
            ;;
        --help|-h) usage; exit 0 ;;
        *)
            printf 'Error: unknown option: %s\n' "$1" >&2
            usage
            exit 1
            ;;
    esac
done

_dotfiles_install
