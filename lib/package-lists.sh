#!/usr/bin/env bash
# Package list reader. Public lists live under packages/<kind>.list;
# optional private overlays under $(_private_path packages/<kind>.list).

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/private.sh
source "${BASH_SOURCE[0]%/*}/private.sh"

_package_list_kinds='pacman|aur|flatpak|node'

# True when name is safe to pass after `--` to pacman/flatpak/npm/yay.
_package_name_valid() {
    local name="${1:-}"
    [[ "$name" =~ ^[A-Za-z0-9@][A-Za-z0-9@._+/:-]*$ ]]
}

# Read one list file. Names before any ## heading belong to group "default".
# Private files without headings use group "private".
# Prints "group|name" lines; missing file prints nothing.
# Rejects invalid package names (returns 1).
_package_list_read_file() {
    local file="$1" default_group="$2"
    local group="$default_group" line name
    local -a names=()
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [ -n "$line" ] || continue
        case "$line" in
            \#\#*)
                group="${line#\#\#}"
                group="${group#"${group%%[![:space:]]*}"}"
                group="${group%"${group##*[![:space:]]}"}"
                [ -n "$group" ] || group="$default_group"
                ;;
            \#*) ;;
            *)
                names=()
                read -ra names <<< "$line"
                for name in "${names[@]}"; do
                    if ! _package_name_valid "$name"; then
                        printf 'Invalid package name in %s: %s\n' "$file" "$name" >&2
                        return 1
                    fi
                    printf '%s|%s\n' "$group" "$name"
                done
                ;;
        esac
    done < "$file"
}

# _package_list <kind> [group]
# Prints one package name per line (deduplicated, public then private).
_package_list() {
    local kind="${1:-}" group_filter="${2:-}"
    local public_file private_file entry name group entries
    local -A seen=()

    case "$kind" in
        pacman|aur|flatpak|node) ;;
        *)
            printf 'Unknown package kind: %s (expected pacman|aur|flatpak|node)\n' "$kind" >&2
            return 2
            ;;
    esac

    public_file="$DOTFILES/packages/${kind}.list"
    private_file="$(_private_path "packages/${kind}.list")"

    if ! entries="$(
        _package_list_read_file "$public_file" default || exit 1
        _package_list_read_file "$private_file" private || exit 1
    )"; then
        return 1
    fi

    while IFS= read -r entry || [ -n "$entry" ]; do
        [ -n "$entry" ] || continue
        group="${entry%%|*}"
        name="${entry#*|}"
        [ -n "$name" ] || continue
        if [ -n "$group_filter" ] && [ "$group" != "$group_filter" ]; then
            continue
        fi
        if [ -n "${seen[$name]+x}" ]; then
            continue
        fi
        seen["$name"]=1
        printf '%s\n' "$name"
    done <<< "$entries"
}
