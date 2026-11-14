#!/usr/bin/env bash
# Shell-script app installers. The only remote download is the pinned,
# checksum-verified oh-my-zsh installer. Honors DOTFILES_DRY_RUN,
# DOTFILES_YES and DOTFILES_NO_REMOTE.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "${BASH_SOURCE[0]%/*}/environments.sh"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"
# shellcheck source=lib/prompt.sh
source "${BASH_SOURCE[0]%/*}/prompt.sh"

_sh_run() {
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

_sh_sudo() {
    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] sudo %s\n' "$*"
        return 0
    fi
    sudo "$@"
}

_remote_table_path() {
    printf '%s\n' "${DOTFILES_REMOTE_TABLE:-$DOTFILES/scripts/remote-installers.conf}"
}

# Look up name|url|sha256 for a remote installer.
_remote_row() {
    local name="$1" table line
    table="$(_remote_table_path)"
    [ -f "$table" ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            \#*|'') continue ;;
        esac
        case "$line" in
            "${name}"\|*)
                printf '%s\n' "$line"
                return 0
                ;;
        esac
    done < "$table"
    return 1
}

_get_default_sh_apps() {
    printf '%s\n' "ohmyzsh mise docker"
}

_get_app_function() {
    local app="$1"
    case "$app" in
        ohmyzsh) printf '%s\n' "_install_ohmyzsh" ;;
        mise) printf '%s\n' "_install_mise" ;;
        docker) printf '%s\n' "_install_docker" ;;
        *) printf '%s\n' "" ;;
    esac
}

_install_ohmyzsh() {
    local row url sum tmp actual
    e_header "Installing oh-my-zsh"

    if [ "${DOTFILES_NO_REMOTE:-0}" = 1 ]; then
        e_warning "Skipping oh-my-zsh (--no-remote / DOTFILES_NO_REMOTE=1)"
        return 0
    fi

    row="$(_remote_row ohmyzsh)" || {
        e_error "No ohmyzsh row in $(_remote_table_path)"
        return 1
    }
    url="$(printf '%s\n' "$row" | cut -d'|' -f2)"
    sum="$(printf '%s\n' "$row" | cut -d'|' -f3)"

    if [ -z "$url" ] || [ -z "$sum" ]; then
        e_error "Invalid ohmyzsh remote row"
        return 1
    fi

    if [ "${DOTFILES_DRY_RUN:-0}" = 1 ]; then
        printf '[dry-run] curl -fsSL %s\n' "$url"
        printf '[dry-run] verify sha256 %s\n' "$sum"
        printf '[dry-run] sh <installer> --unattended\n'
        return 0
    fi

    tmp="$(mktemp "${TMP_DIR:-/tmp}/ohmyzsh-install.XXXXXX")"
    # shellcheck disable=SC2064
    trap 'rm -f "$tmp"' RETURN

    if ! curl -fsSL "$url" -o "$tmp"; then
        e_error "Failed to download oh-my-zsh installer"
        return 1
    fi

    actual="$(sha256sum "$tmp" | cut -d' ' -f1)"
    if [ "$actual" != "$sum" ]; then
        e_error "oh-my-zsh installer checksum mismatch (expected $sum, got $actual)"
        return 1
    fi

    if ! sh "$tmp" --unattended; then
        e_error "oh-my-zsh installer failed"
        return 1
    fi
    e_success "oh-my-zsh installed"
}

_install_mise() {
    e_header "Installing mise"
    _sh_sudo pacman -S --noconfirm --needed mise
}

_install_docker_arch() {
    e_header "Installing Docker (Arch)"
    _sh_sudo pacman -S --noconfirm --needed docker docker-compose || return 1
    if [ "${DOTFILES_DRY_RUN:-0}" != 1 ]; then
        _sh_sudo systemctl enable --now docker || true
        if ! groups | grep -q docker; then
            _sh_sudo usermod -aG docker "${USER:-$(id -un)}"
            e_warning "Log out and back in to apply the docker group"
        fi
    fi
}

_install_docker() {
    if [ "${DOTFILES_IS_ARCH:-false}" = "true" ]; then
        _install_docker_arch
        return $?
    fi
    e_warning "Automatic Docker install is supported on Arch Linux only"
    return 1
}

# _sh_apps [names...]
_sh_apps() {
    local apps_to_install="$1"
    local -a _apps=() failed=()
    local app func

    if [ -z "$apps_to_install" ]; then
        apps_to_install="$(_get_default_sh_apps)"
    fi
    # shellcheck disable=SC2206
    _apps=($apps_to_install)

    if [ "${#_apps[@]}" -eq 0 ]; then
        e_warning "No shell apps selected"
        return 0
    fi

    e_info "Selected shell apps: ${_apps[*]}"

    for app in "${_apps[@]}"; do
        func="$(_get_app_function "$app")"
        if [ -z "$func" ]; then
            e_warning "Unknown shell app: $app"
            continue
        fi
        if ! "$func"; then
            e_warning "Failed to install $app (continuing)"
            failed+=("$app")
        fi
    done

    if [ "${#failed[@]}" -gt 0 ]; then
        e_error "Failed shell apps: ${failed[*]}"
        return 1
    fi
    return 0
}
