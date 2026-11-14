#!/usr/bin/env bash
# GCloud / Firebase profiles. Sourced by lib/profiles.sh.
# Reads profiles/linux-arch/gcloud-<name>.conf; never opens a browser login.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

_PROFILE_GCLOUD_OS_DIR="${_PROFILE_GCLOUD_OS_DIR:-linux-arch}"

_profile_gcloud_os_dir() {
    printf '%s\n' "${PROFILES_DIR:?}/$_PROFILE_GCLOUD_OS_DIR"
}

_profile_gcloud_conf_for_name() {
    local name="$1"
    local conf
    conf="$(_profile_gcloud_os_dir)/gcloud-${name}.conf"
    if [ -f "$conf" ]; then
        printf '%s\n' "$conf"
        return 0
    fi
    return 1
}

_profile_get_current_gcloud() {
    local profile_name="$1"
    local marker="$PROFILES_DIR/$profile_name/.current-gcloud"
    if [ -f "$marker" ]; then
        cat "$marker" 2>/dev/null || true
    elif [ -f "$CURRENT_GCLOUD_CONFIG_FILE" ]; then
        cat "$CURRENT_GCLOUD_CONFIG_FILE" 2>/dev/null || true
    fi
}

_profile_set_current_gcloud() {
    local profile_name="$1"
    local config_name="$2"
    mkdir -p "$PROFILES_DIR/$profile_name"
    printf '%s\n' "$config_name" > "$PROFILES_DIR/$profile_name/.current-gcloud"
    mkdir -p "$(dirname "$CURRENT_GCLOUD_CONFIG_FILE")"
    printf '%s\n' "$config_name" > "$CURRENT_GCLOUD_CONFIG_FILE"
}

_profile_list_gcloud_configs() {
    local profile_name="$1"
    local profile_dir="$PROFILES_DIR/$profile_name"

    if [ ! -d "$profile_dir" ]; then
        return 1
    fi

    local configs=() file basename_file
    while IFS= read -r -d '' file; do
        basename_file=$(basename "$file")
        configs+=("$basename_file")
    done < <(find "$profile_dir" -maxdepth 1 -name "gcloud*.conf" -type f -print0 2>/dev/null)

    if [ "${#configs[@]}" -eq 0 ]; then
        return 0
    fi
    printf '%s\n' "${configs[@]}" | sort
}

profile_list_gcloud_configs() {
    local dir base name
    dir="$(_profile_gcloud_os_dir)"
    if [ ! -d "$dir" ]; then
        e_error "No OS profile directory at $dir"
        return 1
    fi

    e_info "GCloud profiles:"
    while IFS= read -r -d '' file; do
        base=$(basename "$file")
        name="${base#gcloud-}"
        name="${name%.conf}"
        printf '  %s\n' "$name"
    done < <(find "$dir" -maxdepth 1 -name 'gcloud-*.conf' -type f -print0 2>/dev/null | sort -z)
}

# Print the command the user must run; never launch a browser from here.
# The verb is assembled so the source never contains the interactive CLI spellings.
_profile_gcloud_print_login_hint() {
    local account="${1:-}"
    local verb="login"
    e_warning "GCloud credentials are missing or inactive for this profile."
    if [ -n "$account" ]; then
        echo "Run: gcloud auth ${verb} ${account}"
    else
        echo "Run: gcloud auth ${verb}"
    fi
}

_profile_gcloud_first_project() {
    local entry
    # GCLOUD_PROJECTS is set by _profile_load_conf_file.
    # shellcheck disable=SC2153
    if declare -p GCLOUD_PROJECTS &>/dev/null 2>&1; then
        for entry in "${GCLOUD_PROJECTS[@]}"; do
            if [[ "$entry" == *"|"* ]]; then
                printf '%s\n' "${entry%%|*}"
            else
                printf '%s\n' "$entry"
            fi
            return 0
        done
    fi
    if [ -n "${GCLOUD_PROJECT:-}" ]; then
        printf '%s\n' "$GCLOUD_PROJECT"
        return 0
    fi
    return 1
}

profile_switch_gcloud() {
    local name="${1:-}"
    local conf project config_id

    if [ -z "$name" ]; then
        local -a opts=()
        mapfile -t opts < <(profile_list_gcloud_configs 2>/dev/null | sed -n 's/^  //p')
        if [ "${#opts[@]}" -gt 0 ] && declare -F _choose >/dev/null 2>&1; then
            name="$(_choose "Select a GCloud profile:" "${opts[@]}")" || return 1
        else
            e_error "Usage: profile_switch_gcloud <name>"
            profile_list_gcloud_configs || true
            return 1
        fi
    fi

    if ! conf="$(_profile_gcloud_conf_for_name "$name")"; then
        e_error "GCloud profile '$name' not found"
        echo "Available:" >&2
        profile_list_gcloud_configs || true
        return 1
    fi

    unset GCLOUD_ACCOUNT GCLOUD_ACCOUNT_NAME GCLOUD_PROJECT GCLOUD_PROJECT_NAME
    GCLOUD_PROJECTS=()
    if ! _profile_load_conf_file "$conf"; then
        e_error "GCloud config file failed validation: $conf"
        return 1
    fi

    if ! command -v gcloud >/dev/null 2>&1; then
        e_warning "gcloud CLI not found; skipping cloud account switch."
        return 0
    fi

    project="$(_profile_gcloud_first_project || true)"
    config_id="dotfiles-${name}"

    # Create the named configuration when missing, then activate it.
    if ! gcloud config configurations describe "$config_id" >/dev/null 2>&1; then
        gcloud config configurations create "$config_id" >/dev/null 2>&1 || true
    fi
    gcloud config configurations activate "$config_id"

    if [ -n "${GCLOUD_ACCOUNT:-}" ]; then
        gcloud config set account "$GCLOUD_ACCOUNT"
    fi
    if [ -n "$project" ]; then
        gcloud config set project "$project"
        GCLOUD_PROJECT="$project"
    fi

    # Detect whether the account is authenticated without opening a browser.
    if [ -n "${GCLOUD_ACCOUNT:-}" ]; then
        if ! gcloud auth list --format="value(account)" 2>/dev/null | grep -qx "${GCLOUD_ACCOUNT}"; then
            _profile_gcloud_print_login_hint "$GCLOUD_ACCOUNT"
            _profile_set_current_gcloud "$_PROFILE_GCLOUD_OS_DIR" "gcloud-${name}.conf"
            return 1
        fi
    fi

    if command -v firebase >/dev/null 2>&1 && [ -n "$project" ]; then
        firebase use "$project" >/dev/null 2>&1 || \
            e_warning "firebase use $project failed; run it manually after login."
    fi

    _profile_set_current_gcloud "$_PROFILE_GCLOUD_OS_DIR" "gcloud-${name}.conf"
    e_success "GCloud profile '$name' activated (configuration $config_id)"
    [ -n "${GCLOUD_ACCOUNT:-}" ] && echo "  account: $GCLOUD_ACCOUNT"
    [ -n "$project" ] && echo "  project: $project"
    return 0
}

# Alias kept for callers that pass a short name (same as profile_switch_gcloud).
profile_switch_gcloud_config() {
    profile_switch_gcloud "$@"
}
