#!/usr/bin/env bash
# Create development directories listed in DOTFILES_DEV_DIRS.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/validation.sh
source "${BASH_SOURCE[0]%/*}/validation.sh"

_setup_dev_environment() {
    local dir created=0
    local -a dirs=()

    if ! validate_write_permission "$HOME"; then
        e_error "HOME is not writable: $HOME"
        return 1
    fi

    if [ -n "${DOTFILES_DEV_DIRS:-}" ]; then
        # shellcheck disable=SC2206
        dirs=($DOTFILES_DEV_DIRS)
    else
        dirs=("$HOME/dev/projects")
    fi

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            e_arrow "Directory already exists: $dir"
            continue
        fi
        e_info "Creating directory: $dir"
        if mkdir -p "$dir"; then
            created=$((created + 1))
        else
            e_error "Failed to create $dir"
            return 1
        fi
    done

    if [ "$created" -gt 0 ]; then
        e_success "Development directories prepared"
    else
        e_success "Development directories already present"
    fi
    return 0
}
