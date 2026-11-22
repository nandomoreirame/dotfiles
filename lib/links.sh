#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/private.sh
source "${BASH_SOURCE[0]%/*}/private.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"
: "${LINKS_CONFIG:=$DOTFILES/configs/links.conf}"

_trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    printf '%s' "${value%"${value##*[![:space:]]}"}"
}

_parse_config_section() {
    local section="$1" config_file="$2" active=false line
    [ -f "$config_file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(_trim "$line")
        case "$line" in ''|'#'*) continue ;; esac
        if [[ "$line" == \[*\] ]]; then
            active=false
            [ "$line" != "[$section]" ] || active=true
        elif "$active"; then
            printf '%s\n' "$line"
        fi
    done < "$config_file"
}

_link_relative_path() {
    case "$1" in ''|/*|.|..|../*|*/../*|*/..|./*|*/./*|*/.|*$'\n'*|*$'\r'*) return 1 ;; esac
}

# Both creation and verification consume this ordered, deduplicated mapping.
_load_link_entries() {
    local mode="$1" config section line src target _unused overlay=false key
    local -a sections=() configs=("$LINKS_CONFIG")
    _link_targets=()
    unset _link_sources
    declare -gA _link_sources=()
    [ ! -f "$(_private_path links.conf)" ] || configs+=("$(_private_path links.conf)")
    for config in "${configs[@]}"; do
        if [ "$mode" = files ]; then
            sections=(files)
        elif [ "$mode" = paths ]; then
            sections=(paths)
            [ "${DOTFILES_IS_ARCH:-false}" != true ] || sections+=(paths:arch)
        else
            sections=(files paths)
            [ "${DOTFILES_IS_ARCH:-false}" != true ] || sections+=(paths:arch)
        fi
        for section in "${sections[@]}"; do
            while IFS= read -r line; do
                if [ "$section" = files ]; then
                    target="$line"
                    src="configs/$line"
                    if "$overlay"; then
                        src="$DOTFILES_PRIVATE/configs/$line"
                    else
                        src="$DOTFILES/$src"
                    fi
                else
                    [[ "$line" == *'|'* ]] || { printf 'Invalid link entry: %s\n' "$line" >&2; return 1; }
                    IFS='|' read -r src target _unused <<< "$line"
                    src=$(_trim "$src")
                    target=$(_trim "$target")
                    _link_relative_path "$src" || { printf 'Invalid source: %s\n' "$src" >&2; return 1; }
                    if "$overlay" && [[ "$src" == private/* ]]; then
                        src="$DOTFILES_PRIVATE/${src#private/}"
                    else
                        src="$DOTFILES/$src"
                    fi
                fi
                _link_relative_path "$target" || { printf 'Invalid target: %s\n' "$target" >&2; return 1; }
                key="$target"
                if [ -z "${_link_sources[$key]+present}" ]; then
                    _link_targets+=("$key")
                fi
                _link_sources["$key"]="$src"
            done < <(_parse_config_section "$section" "$config")
        done
        overlay=true
    done
}

_load_files_from_config() {
    _load_link_entries files || return 1
    _files=("${_link_targets[@]}")
}

_load_paths_from_config() {
    local target
    _load_link_entries paths || return 1
    _paths=()
    for target in "${_link_targets[@]}"; do
        _paths+=("${_link_sources[$target]}|$target")
    done
}

_backup_or_remove_target() {
    local target_path="$1" backup_path
    [ -e "$target_path" ] || [ -L "$target_path" ] || return 0
    if [ -L "$target_path" ]; then
        rm -- "$target_path"
        return
    fi
    backup_path="${target_path}.bak.$(date +%Y%m%d-%H%M%S)"
    while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
        backup_path="${backup_path}.1"
    done
    mv -- "$target_path" "$backup_path" || return 1
    printf 'Backup created: %s\n' "$backup_path"
}

_create_links() {
    local mode="$1" target src destination parent home_real parent_real missing=false
    _load_link_entries "$mode" || return 1
    for target in "${_link_targets[@]}"; do
        src="${_link_sources[$target]}"
        if [ ! -e "$src" ]; then
            printf 'Missing source: %s\n' "$src" >&2
            missing=true
        fi
    done
    if "$missing"; then
        _confirm 'Continue and skip missing sources?' || return 1
    fi
    home_real=$(realpath -m -- "$HOME") || return 1
    for target in "${_link_targets[@]}"; do
        src="${_link_sources[$target]}"
        if [ ! -e "$src" ]; then
            printf 'Skipping %s (source not found)\n' "$target"
            continue
        fi
        destination="$HOME/$target"
        # Keep a link that already reaches the source, even through another
        # path (for example a symlinked checkout).
        if [ -L "$destination" ] && { [ "$(readlink -- "$destination")" = "$src" ] ||
            [ "$(readlink -f -- "$destination")" = "$(readlink -f -- "$src")" ]; }; then
            continue
        fi
        parent=$(dirname -- "$destination")
        parent_real=$(realpath -m -- "$parent") || return 1
        case "$parent_real/" in "$home_real/"*) ;; *) printf 'Target escapes HOME: %s\n' "$target" >&2; return 1 ;; esac
        mkdir -p -- "$parent" || return 1
        _backup_or_remove_target "$destination" || return 1
        ln -s -- "$src" "$destination" || return 1
        printf 'Linked %s\n' "$target"
    done
}

_link_files() { _create_links files; }
_link_paths() { _create_links paths; }
_links() {
    case "${1:-}" in
        all|--all) _create_links all ;;
        files|--files) _link_files ;;
        paths|--paths) _link_paths ;;
        *) printf '%s\n' 'Usage: dotfiles links [--all|--files|--paths|--help]'; [ "${1:-}" = --help ] ;;
    esac
}
