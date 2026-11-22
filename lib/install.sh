#!/usr/bin/env bash
# New-machine install steps shared by ./install.sh and `dotfiles install`.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/spinner.sh
source "${BASH_SOURCE[0]%/*}/spinner.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"
# shellcheck source=lib/apps.sh
source "${BASH_SOURCE[0]%/*}/apps.sh"
# shellcheck source=lib/setup.sh
source "${BASH_SOURCE[0]%/*}/setup.sh"
# shellcheck source=lib/fonts.sh
source "${BASH_SOURCE[0]%/*}/fonts.sh"
# shellcheck source=lib/dev-environment.sh
source "${BASH_SOURCE[0]%/*}/dev-environment.sh"
# shellcheck source=lib/links.sh
source "${BASH_SOURCE[0]%/*}/links.sh"
# shellcheck source=lib/aur-packages.sh
source "${BASH_SOURCE[0]%/*}/aur-packages.sh"

_INSTALL_FAILED=0
_INSTALL_FAILED_STEPS=()
_INSTALL_GROUP="${DOTFILES_INSTALL_GROUP:-}"

_install_step_failed() {
    e_error "$1 failed"
    _INSTALL_FAILED=1
    _INSTALL_FAILED_STEPS+=("$1")
}

_install_step() {
    local name="$1" func="$2"
    if [ "${DOTFILES_YES:-0}" != 1 ]; then
        if ! _confirm "Run ${name}?"; then
            printf '%s skipped\n' "$name"
            return 0
        fi
    fi
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s\n' "$name"
    fi
    if [ "${DOTFILES_FAIL_STEP:-}" = "$name" ]; then
        _install_step_failed "$name"
        return 0
    fi
    if ! "$func"; then
        _install_step_failed "$name"
        return 0
    fi
    return 0
}

_install_step_prerequisites() {
    e_info "prerequisites"
    local cmd
    for cmd in git curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            e_error "Missing prerequisite: $cmd"
            return 1
        fi
    done
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] sudo pacman -S --needed base-devel git curl\n'
        return 0
    fi
    if [ "${DOTFILES_IS_ARCH:-false}" = "true" ]; then
        local pkg
        local -a missing=()
        for pkg in base-devel git curl; do
            pacman -Q -- "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
        done
        if [ "${#missing[@]}" -eq 0 ]; then
            e_arrow "Prerequisites already installed"
            return 0
        fi
        spin_sudo_prime
        spin_run "Installing ${missing[*]}" sudo pacman -Syu --noconfirm --needed "${missing[@]}" || return 1
    fi
    return 0
}

_install_step_aur_helper() {
    e_info "aur helper"
    if [ -n "$(_get_aur_helper)" ]; then
        e_arrow "AUR helper already present"
        return 0
    fi

    local row url pin tmp
    local -a mkpkg_args=(-si)
    row="$(_remote_row yay)" || {
        e_error "No yay row in $(_remote_table_path)"
        return 1
    }
    url="${row#*|}"
    url="${url%%|*}"
    pin="${row##*|}"
    if [ -z "$url" ] || [ -z "$pin" ]; then
        e_error "Invalid yay remote row"
        return 1
    fi

    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] git clone %s && git checkout %s && makepkg -si\n' "$url" "$pin"
        return 0
    fi

    if [ "${DOTFILES_YES:-0}" = 1 ]; then
        mkpkg_args+=(--noconfirm)
    fi

    tmp="$(mktemp -d)"
    if ! spin_run "Cloning yay" git clone "$url" "$tmp/yay"; then
        rm -rf "$tmp"
        return 1
    fi
    if ! git -C "$tmp/yay" checkout --quiet "$pin"; then
        e_error "Failed to checkout pinned yay commit $pin"
        rm -rf "$tmp"
        return 1
    fi
    # makepkg asks questions without --noconfirm: only spin when it cannot prompt.
    local -a build=()
    if [ "${DOTFILES_YES:-0}" = 1 ]; then
        spin_sudo_prime
        build=(spin_run "Building yay")
    fi
    if ! (cd "$tmp/yay" && "${build[@]}" makepkg "${mkpkg_args[@]}"); then
        rm -rf "$tmp"
        return 1
    fi
    rm -rf "$tmp"
    return 0
}

_install_step_packages() {
    e_info "packages"
    local group="$_INSTALL_GROUP"
    if [ -z "$group" ] && [ "${DOTFILES_YES:-0}" != 1 ]; then
        group="$(_choose "Select package group" all core shell containers vm fonts desktop apps)" || group=all
        printf 'group: %s\n' "$group"
    fi
    [ -n "$group" ] || group=all
    if [ "$group" != "all" ]; then
        _apps_install_pacman "$group" ""
        return
    fi
    # One failing manager must not skip the others.
    local failed=0
    _apps_install_pacman "" "" || failed=1
    _apps_install_aur "" "" || failed=1
    _apps_install_flatpak "" "" || failed=1
    _apps_install_node "" "" || failed=1
    _apps_install_sh "" "" || failed=1
    return "$failed"
}

_install_step_fonts() {
    e_info "fonts"
    _install_fonts
}

_install_step_runtimes() {
    e_info "runtimes"
    if [ ! -f "$DOTFILES/configs/mise/config.toml" ]; then
        e_warning "runtimes: configs/mise/config.toml missing (continuing)"
        return 0
    fi
    _install_mise_packages
}

_install_step_links() {
    e_info "links"
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] dotfiles links create\n'
        return 0
    fi
    _links --all
}

_install_step_setup() {
    e_info "setup"
    _run_setup
}

_install_print_next_steps() {
    printf '\n'
    e_header "Next steps"
    printf '%s\n' \
        "  1. Run: dotfiles init" \
        "  2. Run: dotfiles doctor" \
        "  3. Change your login shell: chsh -s /bin/zsh" \
        "  4. Log out and back in"
}

_dotfiles_install() {
    _INSTALL_FAILED=0
    _INSTALL_FAILED_STEPS=()
    DOTFILES_FAILURES=()
    _INSTALL_GROUP="${DOTFILES_INSTALL_GROUP:-}"

    if [ "${DOTFILES_IS_ARCH:-false}" != "true" ]; then
        e_error "This installer supports Arch Linux only"
        return 1
    fi

    if [ "${DOTFILES_DRY_RUN:-0}" != 1 ]; then
        _setup_dev_environment || true
    fi

    _install_step "prerequisites" _install_step_prerequisites
    _install_step "aur helper" _install_step_aur_helper
    _install_step "packages" _install_step_packages
    _install_step "fonts" _install_step_fonts
    _install_step "runtimes" _install_step_runtimes
    _install_step "links" _install_step_links
    _install_step "setup" _install_step_setup

    _install_print_next_steps
    _install_report
}

# _install_report: end with what failed, so nobody scrolls back to find it.
_install_report() {
    local item
    if [ "$_INSTALL_FAILED" -eq 0 ] && [ "${#DOTFILES_FAILURES[@]}" -eq 0 ]; then
        e_success "Install finished"
        return 0
    fi
    printf '\n'
    e_error "Install finished with failures"
    [ "${#_INSTALL_FAILED_STEPS[@]}" -eq 0 ] || printf '  Failed steps: %s\n' "${_INSTALL_FAILED_STEPS[*]}"
    for item in "${DOTFILES_FAILURES[@]}"; do
        printf '  %s\n' "$item"
    done
    printf '  %s\n' "Scroll up to the matching \"Failed to install\" line for the error."
    return 1
}
