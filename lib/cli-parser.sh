#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/help.sh
source "${BASH_SOURCE[0]%/*}/help.sh"
# shellcheck source=lib/status.sh
source "${BASH_SOURCE[0]%/*}/status.sh"
# shellcheck source=lib/links.sh
source "${BASH_SOURCE[0]%/*}/links.sh"
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

# Parse shared install/remove flags into globals.
# Sets: DOTFILES_DRY_RUN, DOTFILES_YES, DOTFILES_NO_REMOTE,
#        _CLI_GROUP, _CLI_ONLY, and remaining names in _CLI_NAMES.
_cli_parse_pkg_flags() {
    _CLI_GROUP=""
    _CLI_ONLY=""
    _CLI_NAMES=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                export DOTFILES_DRY_RUN=1
                shift
                ;;
            --yes|-y)
                export DOTFILES_YES=1
                shift
                ;;
            --no-remote)
                export DOTFILES_NO_REMOTE=1
                shift
                ;;
            --group)
                [ "$#" -ge 2 ] || { _cli_error "--group needs a value"; return 1; }
                _CLI_GROUP="$2"
                shift 2
                ;;
            --only)
                [ "$#" -ge 2 ] || { _cli_error "--only needs a value"; return 1; }
                _CLI_ONLY="$2"
                shift 2
                ;;
            -i|--interactive)
                _cli_error "interactive menus are not available in this version"
                return 2
                ;;
            --help|-h)
                _help
                return 0
                ;;
            --)
                shift
                _CLI_NAMES+=("$@")
                break
                ;;
            -*)
                _cli_error "Unknown option: $1"
                return 1
                ;;
            *)
                _CLI_NAMES+=("$1")
                shift
                ;;
        esac
    done
    return 0
}

_cli_load_apps() {
    # shellcheck source=lib/apps.sh
    source "${BASH_SOURCE[0]%/*}/apps.sh"
}

_cli_load_remove() {
    # shellcheck source=lib/remove.sh
    source "${BASH_SOURCE[0]%/*}/remove.sh"
}

_pkg_install_handler() {
    local kind="$1"
    shift
    _cli_parse_pkg_flags "$@" || return $?
    _cli_load_apps
    case "$kind" in
        pacman) _apps_install_pacman "$_CLI_GROUP" "${_CLI_ONLY:-${_CLI_NAMES[*]}}" ;;
        aur) _apps_install_aur "$_CLI_GROUP" "${_CLI_ONLY:-${_CLI_NAMES[*]}}" ;;
        flatpak) _apps_install_flatpak "$_CLI_GROUP" "${_CLI_ONLY:-${_CLI_NAMES[*]}}" ;;
        node) _apps_install_node "$_CLI_GROUP" "${_CLI_ONLY:-${_CLI_NAMES[*]}}" ;;
        sh) _apps_install_sh "$_CLI_GROUP" "${_CLI_ONLY:-${_CLI_NAMES[*]}}" ;;
        langs) _apps_install_langs ;;
        fonts) _apps_install_fonts ;;
        apps) _apps_install_all "$_CLI_GROUP" "${_CLI_ONLY:-${_CLI_NAMES[*]}}" ;;
        *) _cli_error "Unknown install kind: $kind"; return 1 ;;
    esac
}

_pkg_remove_handler() {
    local kind="$1"
    shift
    _cli_parse_pkg_flags "$@" || return $?
    if [ "${#_CLI_NAMES[@]}" -eq 0 ]; then
        _cli_error "${kind}:remove needs at least one package name"
        return 1
    fi
    _cli_load_remove
    case "$kind" in
        pacman) _remove_pacman "${_CLI_NAMES[@]}" ;;
        aur) _remove_aur "${_CLI_NAMES[@]}" ;;
        flatpak) _remove_flatpak "${_CLI_NAMES[@]}" ;;
        node) _remove_node "${_CLI_NAMES[@]}" ;;
        *) _cli_error "Unknown remove kind: $kind"; return 1 ;;
    esac
}

# Later milestones register modules here without extending the parser.
_setup_module() {
    case "${1:-}" in
        ""|run)
            # bare `setup` runs auto scripts; `setup:run <name>` runs one
            if [ "${1:-}" = "run" ]; then
                shift
                # shellcheck source=lib/setup.sh
                source "${BASH_SOURCE[0]%/*}/setup.sh"
                _cli_parse_pkg_flags "$@" || return $?
                if [ "${#_CLI_NAMES[@]}" -eq 0 ]; then
                    _cli_error "Usage: dotfiles setup:run <name>"
                    return 1
                fi
                _setup_run_one "${_CLI_NAMES[@]}"
            else
                # shellcheck source=lib/setup.sh
                source "${BASH_SOURCE[0]%/*}/setup.sh"
                _cli_parse_pkg_flags "$@" || return $?
                _run_setup
            fi
            ;;
        *)
            _cli_error "Usage: dotfiles setup | setup:run <name>"
            return 1
            ;;
    esac
}

declare -gA _DOTFILES_MODULES=(
    [links]=_links_handler
    [pacman]=_pacman_module
    [aur]=_aur_module
    [flatpak]=_flatpak_module
    [node]=_node_module
    [sh]=_sh_module
    [langs]=_langs_module
    [fonts]=_fonts_module
    [apps]=_apps_module
    [setup]=_setup_module
)

_pacman_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler pacman "$@" ;;
        remove) shift; _pkg_remove_handler pacman "$@" ;;
        *) _cli_error "Usage: dotfiles pacman:install|pacman:remove"; return 1 ;;
    esac
}
_aur_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler aur "$@" ;;
        remove) shift; _pkg_remove_handler aur "$@" ;;
        *) _cli_error "Usage: dotfiles aur:install|aur:remove"; return 1 ;;
    esac
}
_flatpak_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler flatpak "$@" ;;
        remove) shift; _pkg_remove_handler flatpak "$@" ;;
        *) _cli_error "Usage: dotfiles flatpak:install|flatpak:remove"; return 1 ;;
    esac
}
_node_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler node "$@" ;;
        remove) shift; _pkg_remove_handler node "$@" ;;
        *) _cli_error "Usage: dotfiles node:install|node:remove"; return 1 ;;
    esac
}
_sh_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler sh "$@" ;;
        *) _cli_error "Usage: dotfiles sh:install"; return 1 ;;
    esac
}
_langs_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler langs "$@" ;;
        *) _cli_error "Usage: dotfiles langs:install"; return 1 ;;
    esac
}
_fonts_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler fonts "$@" ;;
        *) _cli_error "Usage: dotfiles fonts:install"; return 1 ;;
    esac
}
_apps_module() {
    case "${1:-}" in
        install) shift; _pkg_install_handler apps "$@" ;;
        *) _cli_error "Usage: dotfiles apps:install"; return 1 ;;
    esac
}

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
        *:*)
            # Support "module:action" as a single token.
            local mod="${1%%:*}" act="${1#*:}"
            shift
            _dispatch "$mod" "$act" "$@"
            ;;
        *) _dispatch "$@" ;;
    esac
}
