#!/usr/bin/env bash
# Command surface: noun-verb subcommands separated by spaces
# (`dotfiles packages install --manager pacman`). Actions are never flags.
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/help.sh
source "${BASH_SOURCE[0]%/*}/help.sh"
# shellcheck source=lib/status.sh
source "${BASH_SOURCE[0]%/*}/status.sh"
# shellcheck source=lib/links.sh
source "${BASH_SOURCE[0]%/*}/links.sh"
DOTFILES_VERSION=0.1.0
readonly _CLI_MANAGERS="pacman aur flatpak node sh"

_cli_error() { printf 'Error: %s\n' "$*" >&2; }
_cli_warn() { printf 'Warning: %s\n' "$*" >&2; }
_cli_info() { printf '%s\n' "$*"; }
_cli_success() { printf '%s\n' "$*"; }
_version() {
    printf 'dotfiles v%s\nEnvironment manager\nOS: %s\nPath: %s\n' \
        "$DOTFILES_VERSION" "$DOTFILES_OS" "$DOTFILES"
}

# _cli_no_args <usage-topic> <args...>: fail when any argument is left.
_cli_no_args() {
    local topic="$1"
    shift
    [ "$#" -eq 0 ] && return 0
    _cli_error "Unexpected arguments: $*"
    _help "$topic" >&2
    return 1
}

_links_handler() {
    local action="${1:-}"
    shift || true
    case "$action" in
        create)
            case "${1:-}" in
                --help|-h) _help links; return 0 ;;
                --files|--paths) local scope="$1"; shift; _cli_no_args links "$@" || return 1; _links "$scope" ;;
                "") _links --all ;;
                *) _cli_no_args links "$@" ;;
            esac
            ;;
        verify)
            case "${1:-}" in --help|-h) _help links; return 0 ;; esac
            _cli_no_args links "$@" || return 1
            _verify
            ;;
        --help|-h) _help links ;;
        "") _help links; return 1 ;;
        *) _cli_error "Unknown links action: $action"; _help links; return 1 ;;
    esac
}

# Parse the shared options into globals.
# Sets: DOTFILES_DRY_RUN, DOTFILES_YES, DOTFILES_NO_REMOTE, _CLI_GROUP,
#       _CLI_MANAGER, _CLI_HELP and the positional names in _CLI_NAMES.
_cli_parse_pkg_flags() {
    _CLI_GROUP=""
    _CLI_MANAGER=""
    _CLI_HELP=0
    _CLI_NAMES=()
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run) export DOTFILES_DRY_RUN=1; shift ;;
            --yes|-y) export DOTFILES_YES=1; shift ;;
            --no-remote) export DOTFILES_NO_REMOTE=1; shift ;;
            --group)
                [ "$#" -ge 2 ] || { _cli_error "--group needs a value"; return 1; }
                _CLI_GROUP="$2"
                shift 2
                ;;
            --group=*) _CLI_GROUP="${1#--group=}"; shift ;;
            --manager)
                [ "$#" -ge 2 ] && [[ "$2" != -* ]] || { _cli_error "--manager needs a value"; return 1; }
                _CLI_MANAGER="$2"
                shift 2
                ;;
            --manager=*)
                _CLI_MANAGER="${1#--manager=}"
                [ -n "$_CLI_MANAGER" ] || { _cli_error "--manager needs a value"; return 1; }
                shift
                ;;
            --help|-h) _CLI_HELP=1; shift ;;
            --) shift; _CLI_NAMES+=("$@"); break ;;
            -*) _cli_error "Unknown option: $1"; return 1 ;;
            *) _CLI_NAMES+=("$1"); shift ;;
        esac
    done
    return 0
}

# _cli_check_manager <name>: accept only the known package managers.
_cli_check_manager() {
    case " $_CLI_MANAGERS " in
        *" $1 "*) return 0 ;;
    esac
    _cli_error "Unknown manager: $1 (use one of: ${_CLI_MANAGERS// /, })"
    return 1
}

_cli_load_apps() {
    # shellcheck source=lib/apps.sh
    source "${BASH_SOURCE[0]%/*}/apps.sh"
}

_cli_load_remove() {
    # shellcheck source=lib/remove.sh
    source "${BASH_SOURCE[0]%/*}/remove.sh"
}

_packages_install() {
    local pkg_names="${_CLI_NAMES[*]}"
    _cli_load_apps
    if [ -z "$_CLI_MANAGER" ]; then
        if [ -n "$pkg_names" ]; then
            _cli_error "Package names need --manager"
            return 1
        fi
        _apps_install_all "$_CLI_GROUP" ""
        return
    fi
    _cli_check_manager "$_CLI_MANAGER" || return 1
    "_apps_install_$_CLI_MANAGER" "$_CLI_GROUP" "$pkg_names"
}

_packages_remove() {
    if [ -z "$_CLI_MANAGER" ]; then
        _cli_error "packages remove needs --manager <m>"
        return 1
    fi
    _cli_check_manager "$_CLI_MANAGER" || return 1
    if [ "$_CLI_MANAGER" = sh ]; then
        _cli_error "packages remove cannot remove with the sh manager"
        return 1
    fi
    if [ "${#_CLI_NAMES[@]}" -eq 0 ]; then
        _cli_error "packages remove needs at least one package name"
        return 1
    fi
    _cli_load_remove
    "_remove_$_CLI_MANAGER" "${_CLI_NAMES[@]}"
}

_packages_module() {
    local action="${1:-}"
    shift || true
    case "$action" in
        install|remove)
            _cli_parse_pkg_flags "$@" || return $?
            if [ "$_CLI_HELP" = 1 ]; then
                _help packages
                return 0
            fi
            "_packages_$action"
            ;;
        --help|-h) _help packages ;;
        "") _help packages; return 1 ;;
        *) _cli_error "Unknown packages action: $action"; _help packages; return 1 ;;
    esac
}

# _single_install_module <kind> <action> [options]: langs and fonts.
_single_install_module() {
    local kind="$1" action="${2:-}"
    shift 2 || shift $#
    case "$action" in
        install)
            _cli_parse_pkg_flags "$@" || return $?
            [ "$_CLI_HELP" = 1 ] && { _help; return 0; }
            _cli_no_args "" "${_CLI_NAMES[@]}" || return 1
            _cli_load_apps
            "_apps_install_$kind"
            ;;
        *) _cli_error "Usage: dotfiles $kind install"; return 1 ;;
    esac
}
_langs_module() { _single_install_module langs "$@"; }
_fonts_module() { _single_install_module fonts "$@"; }

_setup_module() {
    # shellcheck source=lib/setup.sh
    source "${BASH_SOURCE[0]%/*}/setup.sh"
    case "${1:-}" in
        --help|-h) _help setup ;;
        run)
            shift
            case "${1:-}" in
                --help|-h) _help setup; return 0 ;;
                ""|-*) _cli_error "Usage: dotfiles setup run <name> [<args>...]"; return 1 ;;
            esac
            # The script owns its own arguments (for example --check).
            _setup_run_one "$@"
            ;;
        ""|-*)
            _cli_parse_pkg_flags "$@" || return $?
            [ "$_CLI_HELP" = 1 ] && { _help setup; return 0; }
            _cli_no_args setup "${_CLI_NAMES[@]}" || return 1
            _run_setup
            ;;
        *) _cli_error "Unknown setup action: $1"; _help setup; return 1 ;;
    esac
}

_status_module() {
    case "${1:-}" in --help|-h) _help status; return 0 ;; esac
    _cli_no_args status "$@" || return 1
    _status
}

_profile_cli_load() {
    # shellcheck source=lib/output.sh
    source "${BASH_SOURCE[0]%/*}/output.sh"
    # shellcheck source=lib/profiles.sh
    source "${BASH_SOURCE[0]%/*}/profiles.sh"
}

_profile_cli_list_identities() {
    local dir file base name
    dir="${PROFILES_DIR:?}/linux-arch"
    if [ ! -d "$dir" ]; then
        _cli_error "No identity profiles under $dir"
        return 1
    fi
    printf 'Identity profiles:\n'
    while IFS= read -r -d '' file; do
        base=$(basename "$file")
        name="${base#git-}"
        name="${name%.conf}"
        printf '  %s\n' "$name"
    done < <(find "$dir" -maxdepth 1 -name 'git-*.conf' -type f -print0 2>/dev/null | sort -z)
}

_profile_cli_active_identity() {
    local current=""
    if [ -f "${CURRENT_GIT_CONFIG_FILE:-}" ]; then
        current=$(tr -d '\n' < "$CURRENT_GIT_CONFIG_FILE")
    fi
    current="${current#git-}"
    current="${current%.conf}"
    printf '%s\n' "$current"
}

_profile_cli_show_identity() {
    local name="${1:-}" conf
    if [ -z "$name" ]; then
        name="$(_profile_cli_active_identity)"
        if [ -z "$name" ]; then
            _cli_error "No active identity profile"
            return 1
        fi
    fi
    conf="${PROFILES_DIR:?}/linux-arch/git-${name}.conf"
    if [ ! -f "$conf" ]; then
        _cli_error "Identity profile '$name' not found"
        return 1
    fi
    printf 'Active identity: %s\n' "$name"
    _profile_unset_identity_vars
    if _profile_load_conf_file "$conf" 2>/dev/null; then
        printf '  name:  %s\n' "${GIT_NAME:-not configured}"
        printf '  email: %s\n' "${GIT_EMAIL:-not configured}"
    fi
    return 0
}

_profile_cli_validate_identity() {
    local name="${1:-}" conf
    if [ -z "$name" ]; then
        name="$(_profile_cli_active_identity)"
        if [ -z "$name" ]; then
            _cli_error "Usage: dotfiles profile validate <name>"
            return 1
        fi
    fi
    conf="${PROFILES_DIR:?}/linux-arch/git-${name}.conf"
    if [ ! -f "$conf" ]; then
        _cli_error "Identity profile '$name' not found"
        return 1
    fi
    _profile_unset_identity_vars
    if ! _profile_load_conf_file "$conf"; then
        _cli_error "Identity profile '$name' failed validation"
        return 1
    fi
    if [ -z "${GIT_NAME:-}" ] || [ -z "${GIT_EMAIL:-}" ]; then
        _cli_error "Identity profile '$name': GIT_NAME and GIT_EMAIL must be non-empty"
        return 1
    fi
    printf 'Identity profile %s is valid\n' "$name"
    return 0
}

_profile_cli_switch_identity() {
    local name="${1:-}"
    if [ -z "$name" ]; then
        _cli_error "Usage: dotfiles profile switch <name>"
        _profile_cli_list_identities || true
        return 1
    fi
    profile_switch_git "$name" || return $?
    profile_switch_gcloud "$name" || true
    return 0
}

_profile_module() {
    _profile_cli_load
    local action="${1:-}"
    shift || true
    case "$action" in
        ""|list)
            _profile_cli_list_identities
            ;;
        show)
            _profile_cli_show_identity "${1:-}"
            ;;
        switch)
            _profile_cli_switch_identity "${1:-}"
            ;;
        validate)
            _profile_cli_validate_identity "${1:-}"
            ;;
        create)
            profile_create "${1:-}"
            ;;
        edit)
            profile_edit "${1:-}"
            ;;
        delete)
            profile_delete "${1:-}"
            ;;
        export)
            profile_export "${1:-}" "${2:-}"
            ;;
        import)
            profile_import "${1:-}"
            ;;
        --help|-h)
            _help profile
            ;;
        *)
            _cli_error "Usage: dotfiles profile list|show|switch|create|edit|delete|export|import|validate"
            return 1
            ;;
    esac
}

_hooks_module() {
    # shellcheck source=lib/hooks.sh
    source "${BASH_SOURCE[0]%/*}/hooks.sh"
    local action="${1:-status}"
    shift || true
    case "$action" in
        ""|status)
            _hooks_status
            ;;
        enable)
            _hooks_enable "$@"
            ;;
        disable)
            _hooks_disable
            ;;
        --help|-h)
            _help hooks
            ;;
        *)
            _cli_error "Usage: dotfiles hooks enable|disable|status"
            return 1
            ;;
    esac
}

declare -gA _DOTFILES_MODULES=(
    [links]=_links_handler
    [packages]=_packages_module
    [langs]=_langs_module
    [fonts]=_fonts_module
    [setup]=_setup_module
    [status]=_status_module
    [init]=_init_module
    [doctor]=_doctor_module
    [install]=_install_module
    [profile]=_profile_module
    [hooks]=_hooks_module
    [tui]=_tui_module
)

# The TUI runs as its own process: tui.sh changes shell options and the locale.
_tui_module() {
    exec "$_DOTFILES_CODE_ROOT/bin/utils/dotfiles-tui" "$@"
}

_install_module() {
    # shellcheck source=lib/install.sh
    source "${BASH_SOURCE[0]%/*}/install.sh"
    _cli_parse_pkg_flags "$@" || return $?
    [ "$_CLI_HELP" = 1 ] && { _help install; return 0; }
    _cli_no_args install "${_CLI_NAMES[@]}" || return 1
    if [ -n "${_CLI_GROUP:-}" ]; then
        export DOTFILES_INSTALL_GROUP="$_CLI_GROUP"
    fi
    _dotfiles_install
}

_init_module() {
    # shellcheck source=lib/init.sh
    source "${BASH_SOURCE[0]%/*}/init.sh"
    _cli_parse_pkg_flags "$@" || return $?
    [ "$_CLI_HELP" = 1 ] && { _help; return 0; }
    _dotfiles_init
}

_doctor_module() {
    # shellcheck source=lib/doctor.sh
    source "${BASH_SOURCE[0]%/*}/doctor.sh"
    _cli_parse_pkg_flags "$@" || return $?
    [ "$_CLI_HELP" = 1 ] && { _help; return 0; }
    _doctor
}

_dispatch() {
    local module="${1:-}" handler
    shift || return 1
    if [ -z "$module" ] || [ -z "${_DOTFILES_MODULES[$module]+present}" ]; then
        _cli_error "Unknown command: $module"
        _help >&2
        return 1
    fi
    handler="${_DOTFILES_MODULES[$module]}"
    "$handler" "$@"
}

_parse_command() {
    [ "$#" -gt 0 ] || { _help; return 0; }
    case "$1" in
        --help|-h|--version|-V)
            [ "$#" -eq 1 ] || { _cli_error "Unexpected arguments: $*"; _help >&2; return 1; }
            case "$1" in
                --help|-h) _help ;;
                --version|-V) _version ;;
            esac
            ;;
        -*)
            _cli_error "Unknown option: $1"
            _help >&2
            return 1
            ;;
        *) _dispatch "$@" ;;
    esac
}
