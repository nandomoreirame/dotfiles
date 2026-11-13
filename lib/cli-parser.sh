#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/help.sh
source "${BASH_SOURCE[0]%/*}/help.sh"
# shellcheck source=lib/status.sh
source "${BASH_SOURCE[0]%/*}/status.sh"
DOTFILES_VERSION=0.1.0

_cli_error() { printf 'Error: %s\n' "$*" >&2; }
_cli_warn() { printf 'Warning: %s\n' "$*" >&2; }
_cli_info() { printf '%s\n' "$*"; }
_cli_success() { printf '%s\n' "$*"; }
_version() {
    printf 'dotfiles v%s\nEnvironment manager\nOS: %s\nPath: %s\n' \
        "$DOTFILES_VERSION" "$DOTFILES_OS" "$DOTFILES"
}

_links_handler() {
    if [ "$#" -ne 1 ]; then
        _help -l
        return 1
    fi
    case "$1" in
        --help|-h) _help -l ;;
        --all|--files|--paths) _links "$1" ;;
        *) _cli_error "Unknown links option: $1"; _help -l; return 1 ;;
    esac
}

# Later milestones register modules here without extending the parser.
declare -gA _DOTFILES_MODULES=([links]=_links_handler)
_dispatch() {
    local module="${1:-}" handler
    shift || return 1
    if [ -z "$module" ] || [ -z "${_DOTFILES_MODULES[$module]+present}" ]; then
        _cli_error "Unknown module: $module. Available modules: ${!_DOTFILES_MODULES[*]}"
        _help
        return 1
    fi
    handler="${_DOTFILES_MODULES[$module]}"
    "$handler" "$@"
}

_parse_command() {
    [ "$#" -gt 0 ] || { _help; return 0; }
    case "$1" in
        --help|-h|--version|-v|--status|--verify)
            [ "$#" -eq 1 ] || { _cli_error "Unexpected arguments: $*"; _help; return 1; }
            case "$1" in
                --help|-h) _help ;;
                --version|-v) _version ;;
                --status) _status ;;
                --verify) _verify ;;
            esac
            ;;
        *) _dispatch "$@" ;;
    esac
}
