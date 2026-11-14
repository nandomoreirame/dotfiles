#!/usr/bin/env bash
# Git identity profiles. Sourced by lib/profiles.sh.
# Reads profiles/linux-arch/git-<name>.conf and writes ~/.gitconfig.local.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

_PROFILE_GIT_OS_DIR="${_PROFILE_GIT_OS_DIR:-linux-arch}"

_profile_git_os_dir() {
    printf '%s\n' "${PROFILES_DIR:?}/$_PROFILE_GIT_OS_DIR"
}

_profile_git_conf_for_name() {
    local name="$1"
    local dir conf
    dir="$(_profile_git_os_dir)"
    conf="$dir/git-${name}.conf"
    if [ -f "$conf" ]; then
        printf '%s\n' "$conf"
        return 0
    fi
    return 1
}

_profile_get_current_git() {
    local profile_name="$1"
    local marker="$PROFILES_DIR/$profile_name/.current-git"
    if [ -f "$marker" ]; then
        cat "$marker" 2>/dev/null || true
    elif [ -f "$CURRENT_GIT_CONFIG_FILE" ]; then
        cat "$CURRENT_GIT_CONFIG_FILE" 2>/dev/null || true
    fi
}

_profile_set_current_git() {
    local profile_name="$1"
    local config_name="$2"
    mkdir -p "$PROFILES_DIR/$profile_name"
    printf '%s\n' "$config_name" > "$PROFILES_DIR/$profile_name/.current-git"
    mkdir -p "$(dirname "$CURRENT_GIT_CONFIG_FILE")"
    printf '%s\n' "$config_name" > "$CURRENT_GIT_CONFIG_FILE"
}

# List git*.conf basenames inside one profile directory (used by core show).
_profile_list_git_configs() {
    local profile_name="$1"
    local profile_dir="$PROFILES_DIR/$profile_name"

    if [ ! -d "$profile_dir" ]; then
        return 1
    fi

    local configs=()
    local file basename_file
    while IFS= read -r -d '' file; do
        basename_file=$(basename "$file")
        configs+=("$basename_file")
    done < <(find "$profile_dir" -maxdepth 1 -name "git*.conf" -type f -print0 2>/dev/null)

    if [ "${#configs[@]}" -eq 0 ]; then
        return 0
    fi
    printf '%s\n' "${configs[@]}" | sort
}

# Short names available under the OS profile dir (personal, work, ...).
profile_list_git_configs() {
    local dir name base
    dir="$(_profile_git_os_dir)"
    if [ ! -d "$dir" ]; then
        e_error "No OS profile directory at $dir"
        return 1
    fi

    e_info "Git identity profiles:"
    while IFS= read -r -d '' file; do
        base=$(basename "$file")
        name="${base#git-}"
        name="${name%.conf}"
        printf '  %s\n' "$name"
    done < <(find "$dir" -maxdepth 1 -name 'git-*.conf' -type f -print0 2>/dev/null | sort -z)
}

profile_switch_git() {
    local name="${1:-}"
    local conf dir

    if [ -z "$name" ]; then
        local -a opts=()
        mapfile -t opts < <(profile_list_git_configs 2>/dev/null | sed -n 's/^  //p')
        if [ "${#opts[@]}" -gt 0 ] && declare -F _choose >/dev/null 2>&1; then
            name="$(_choose "Select a Git identity:" "${opts[@]}")" || return 1
        else
            e_error "Usage: profile_switch_git <name>"
            profile_list_git_configs || true
            return 1
        fi
    fi

    if ! conf="$(_profile_git_conf_for_name "$name")"; then
        e_error "Git identity '$name' not found"
        echo "Available:" >&2
        dir="$(_profile_git_os_dir)"
        if [ -d "$dir" ]; then
            local file base short
            while IFS= read -r -d '' file; do
                base=$(basename "$file")
                short="${base#git-}"
                short="${short%.conf}"
                printf '  %s\n' "$short" >&2
            done < <(find "$dir" -maxdepth 1 -name 'git-*.conf' -type f -print0 2>/dev/null | sort -z)
        fi
        return 1
    fi

    unset GIT_NAME GIT_EMAIL GIT_SIGNING_KEY GIT_GPG_KEY \
        GIT_GPG_FORMAT GIT_GPG_PROGRAM GIT_GPG_SSH_PROGRAM GIT_GPG_ALLOWED_SIGNERS
    if ! _profile_load_conf_file "$conf"; then
        e_error "Git config file failed validation: $conf"
        return 1
    fi

    local git_local="$HOME/.gitconfig.local"
    touch "$git_local"
    chmod 600 "$git_local" 2>/dev/null || true

    # Drop the previous identity's signing settings so a switch to a profile
    # without a key cannot keep signing with the earlier key.
    git config --file "$git_local" --unset-all user.signingkey 2>/dev/null || true
    git config --file "$git_local" --unset-all gpg.format 2>/dev/null || true
    git config --file "$git_local" --unset-all gpg.program 2>/dev/null || true
    git config --file "$git_local" --unset-all gpg.ssh.program 2>/dev/null || true
    git config --file "$git_local" --unset-all gpg.ssh.allowedSignersFile 2>/dev/null || true
    git config --file "$git_local" --unset-all commit.gpgsign 2>/dev/null || true

    if [ -n "${GIT_NAME:-}" ]; then
        git config --file "$git_local" user.name "$GIT_NAME"
    fi
    if [ -n "${GIT_EMAIL:-}" ]; then
        git config --file "$git_local" user.email "$GIT_EMAIL"
    fi
    if [ -n "${GIT_SIGNING_KEY:-}" ]; then
        git config --file "$git_local" user.signingkey "$GIT_SIGNING_KEY"
    elif [ -n "${GIT_GPG_KEY:-}" ]; then
        git config --file "$git_local" user.signingkey "$GIT_GPG_KEY"
    fi
    if [ -n "${GIT_GPG_FORMAT:-}" ]; then
        git config --file "$git_local" gpg.format "$GIT_GPG_FORMAT"
    fi
    if [ -n "${GIT_GPG_PROGRAM:-}" ]; then
        git config --file "$git_local" gpg.program "$GIT_GPG_PROGRAM"
    fi
    if [ -n "${GIT_GPG_SSH_PROGRAM:-}" ]; then
        git config --file "$git_local" gpg.ssh.program "$GIT_GPG_SSH_PROGRAM"
    fi
    if [ -n "${GIT_GPG_ALLOWED_SIGNERS:-}" ]; then
        git config --file "$git_local" gpg.ssh.allowedSignersFile "$GIT_GPG_ALLOWED_SIGNERS"
    fi
    if [ -n "${GIT_SIGNING_KEY:-}" ] || [ -n "${GIT_GPG_KEY:-}" ]; then
        git config --file "$git_local" commit.gpgsign true
    fi

    _profile_set_current_git "$_PROFILE_GIT_OS_DIR" "git-${name}.conf"

    e_success "Git identity '$name' applied to ~/.gitconfig.local"
    [ -n "${GIT_NAME:-}" ] && echo "  name:  $GIT_NAME"
    [ -n "${GIT_EMAIL:-}" ] && echo "  email: $GIT_EMAIL"
    [ -n "${GIT_GPG_FORMAT:-}" ] && echo "  format: $GIT_GPG_FORMAT"
    return 0
}
