#!/usr/bin/env bash
# Setup script runner. Registry is data in scripts/setup/registry.conf
# plus an optional private overlay. Honors DOTFILES_DRY_RUN.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/spinner.sh
source "${BASH_SOURCE[0]%/*}/spinner.sh"
# shellcheck source=lib/private.sh
source "${BASH_SOURCE[0]%/*}/private.sh"

SETUP_DIR="$DOTFILES/scripts/setup"

_setup_read_registry() {
    local file="$1" line
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line#"${line%%[![:space:]]*}"}"
        [ -n "$line" ] || continue
        case "$line" in
            \#*) continue ;;
        esac
        printf '%s\n' "$line"
    done < "$file"
}

_get_setup_scripts() {
    _setup_read_registry "$SETUP_DIR/registry.conf"
    _setup_read_registry "$(_private_path setup/registry.conf)"
}

_setup_resolve_path() {
    local file="$1" path
    path="$SETUP_DIR/$file"
    if [ -f "$path" ]; then
        printf '%s\n' "$path"
        return 0
    fi
    path="$(_private_path "setup/$file")"
    if [ -f "$path" ]; then
        printf '%s\n' "$path"
        return 0
    fi
    return 1
}

_setup_exec() {
    local file="$1" desc="${2:-$1}" path
    if ! path="$(_setup_resolve_path "$file")"; then
        e_arrow "Setup '$file' not found (skipping)"
        return 0
    fi
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s (%s)\n' "$file" "$desc"
        return 0
    fi
    # Auto steps are non-interactive; sudo is asked for before the spinner.
    spin_sudo_prime
    if ! spin_run "Setup: $desc" bash "$path"; then
        e_warning "'$file' failed (continuing)"
        return 1
    fi
    return 0
}

_run_setup() {
    local file policy desc
    local failures=0
    e_header "Setup scripts (policy: auto)"
    while IFS='|' read -r file policy desc || [ -n "$file" ]; do
        [ -n "$file" ] || continue
        [ "$policy" = "auto" ] || continue
        if ! _setup_exec "$file" "$desc"; then
            failures=$((failures + 1))
        fi
    done < <(_get_setup_scripts)
    if [ "$failures" -gt 0 ]; then
        return 1
    fi
    return 0
}

_setup_run_one() {
    local name="${1:-}" file policy desc path
    if [ -z "$name" ]; then
        e_error "Usage: dotfiles setup run <name>"
        return 1
    fi
    shift || true
    case "$name" in
        *.sh) ;;
        *) name="${name}.sh" ;;
    esac

    while IFS='|' read -r file policy desc || [ -n "$file" ]; do
        [ -n "$file" ] || continue
        if [ "$file" = "$name" ]; then
            if ! path="$(_setup_resolve_path "$file")"; then
                e_error "'$file' is registered but missing"
                return 1
            fi
            if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
                printf '[dry-run] %s\n' "$file"
                return 0
            fi
            e_info "Setup: $desc ($file)"
            bash "$path" "$@"
            return $?
        fi
    done < <(_get_setup_scripts)

    e_error "Unknown setup script: $name"
    return 1
}

# Alias used by some callers.
_run_setup_one() { _setup_run_one "$@"; }
