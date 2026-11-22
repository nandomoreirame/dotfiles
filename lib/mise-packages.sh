#!/usr/bin/env bash
# Install language runtimes declared in configs/mise/config.toml.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/spinner.sh
source "${BASH_SOURCE[0]%/*}/spinner.sh"

_install_mise_packages() {
    local config_file="$DOTFILES/configs/mise/config.toml"

    if [ ! -f "$config_file" ]; then
        e_error "mise config not found: $config_file"
        return 1
    fi

    if ! command -v mise >/dev/null 2>&1; then
        e_error "mise not found on PATH; install it first (pacman -S mise)"
        return 1
    fi

    e_header "Installing languages via mise"

    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] mise install\n'
        return 0
    fi

    if ! spin_run "Installing runtimes with mise" mise install; then
        e_error "mise install failed"
        return 1
    fi
    e_success "mise languages installed"
}
