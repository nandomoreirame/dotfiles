#!/usr/bin/env bash
# Part of lib/profiles.sh loader. Do not source directly without the loader.
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=lib/environments.sh
source "$DOTFILES/lib/environments.sh"
# shellcheck source=lib/prompt.sh
source "$DOTFILES/lib/prompt.sh"

_profile_exists() {
    local profile_name="$1"
    [ -d "$PROFILES_DIR/$profile_name" ]
}

_profile_validate_name() {
    local profile_name="$1"

    if [ -z "$profile_name" ]; then
        return 1
    fi

    if [[ ! "$profile_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi

    if [[ "$profile_name" == *"/"* ]] || [[ "$profile_name" == *".."* ]]; then
        return 1
    fi

    return 0
}

_profile_validate_path() {
    local profile_name="$1"
    local profile_path="$PROFILES_DIR/$profile_name"

    if ! _profile_validate_name "$profile_name"; then
        return 1
    fi

    local resolved_path
    resolved_path=$(readlink -f "$profile_path" 2>/dev/null || echo "$profile_path")
    local resolved_dir
    resolved_dir=$(readlink -f "$PROFILES_DIR" 2>/dev/null || echo "$PROFILES_DIR")

    if [[ "$resolved_path" != "$resolved_dir"/* ]]; then
        return 1
    fi

    return 0
}

_profile_get_current() {
    if [ -f "$CURRENT_PROFILE_FILE" ]; then
        cat "$CURRENT_PROFILE_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

_profile_set_current() {
    local profile_name="$1"
    echo "$profile_name" > "$CURRENT_PROFILE_FILE"
}

# Shared by core, git and gcloud modules: reject config files with shell metacharacters.
_profile_validate_config_file() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    if grep -qE '(rm\s+-rf|exec\s+|eval\s+|`|\$\(\(|\$\([^)]*\))' "$config_file" 2>/dev/null; then
        return 1
    fi

    return 0
}

profile_list() {
    echo "Available profiles:"
    echo ""

    if [ ! -d "$PROFILES_DIR" ]; then
        echo "  No profile found"
        echo "  Use 'dotfiles profile create' to create one"
        return 1
    fi

    local current_profile
    current_profile=$(_profile_get_current)
    local profiles=()

    while IFS= read -r -d '' profile; do
        profiles+=("$(basename "$profile")")
    done < <(find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

    if [ ${#profiles[@]} -eq 0 ]; then
        echo "  No profile found"
        echo "  Use 'dotfiles profile create' to create one"
        return 1
    fi

    for profile in "${profiles[@]}"; do
        if [ "$profile" = "$current_profile" ]; then
            echo "  $profile (active)"
        else
            echo "  $profile"
        fi
    done

    echo ""
    return 0
}

profile_show() {
    local profile_name="${1:-}"

    if [ -z "$profile_name" ]; then
        profile_name=$(_profile_get_current)
        if [ -z "$profile_name" ]; then
            echo "No active profile"
            return 1
        fi
    fi

    if ! _profile_validate_name "$profile_name"; then
        echo "Invalid profile name"
        return 1
    fi

    if ! _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' not found"
        return 1
    fi

    echo "Profile: $profile_name"
    echo ""

    local git_configs=()
    if declare -F _profile_list_git_configs >/dev/null 2>&1; then
        while IFS= read -r config; do
            [ -n "$config" ] && git_configs+=("$config")
        done < <(_profile_list_git_configs "$profile_name" 2>/dev/null)
    fi

    if [ ${#git_configs[@]} -gt 0 ]; then
        echo "Git:"
        local current_git_config=""
        if declare -F _profile_get_current_git >/dev/null 2>&1; then
            current_git_config=$(_profile_get_current_git "$profile_name")
        fi

        echo "  Available configurations:"
        for config in "${git_configs[@]}"; do
            local marker=""
            if [ "$config" = "$current_git_config" ]; then
                marker=" (active)"
            fi
            echo "    - $config$marker"
        done
        echo ""

        if [ -n "$current_git_config" ]; then
            local git_conf="$PROFILES_DIR/$profile_name/$current_git_config"
            if [ -f "$git_conf" ] && _profile_validate_config_file "$git_conf"; then
                # shellcheck source=/dev/null
                source "$git_conf" 2>/dev/null || true
                echo "  Active configuration ($current_git_config):"
                echo "    Name:  ${GIT_NAME:-not configured}"
                echo "    Email: ${GIT_EMAIL:-not configured}"
                if [ -n "${GIT_SIGNING_KEY:-}" ]; then
                    echo "    SigningKey: ${GIT_SIGNING_KEY}"
                elif [ -n "${GIT_GPG_KEY:-}" ]; then
                    echo "    GPG Key: ${GIT_GPG_KEY}"
                else
                    echo "    SigningKey: not configured"
                fi
                if [ -n "${GIT_GPG_PROGRAM:-}" ]; then
                    echo "    GPG Program: ${GIT_GPG_PROGRAM}"
                fi
                if [ -n "${GIT_GPG_FORMAT:-}" ]; then
                    echo "    GPG Format: ${GIT_GPG_FORMAT}"
                fi
                if [ -n "${GIT_GPG_SSH_PROGRAM:-}" ]; then
                    echo "    GPG SSH Program: ${GIT_GPG_SSH_PROGRAM}"
                fi
            fi
        else
            echo "  No active Git configuration"
        fi
        echo ""
    else
        echo "Git: no configuration available"
        echo ""
    fi

    local gcloud_configs=()
    if declare -F _profile_list_gcloud_configs >/dev/null 2>&1; then
        while IFS= read -r config; do
            [ -n "$config" ] && gcloud_configs+=("$config")
        done < <(_profile_list_gcloud_configs "$profile_name" 2>/dev/null)
    fi

    if [ ${#gcloud_configs[@]} -gt 0 ]; then
        echo "GCloud/Firebase:"
        local current_gcloud_config=""
        if declare -F _profile_get_current_gcloud >/dev/null 2>&1; then
            current_gcloud_config=$(_profile_get_current_gcloud "$profile_name")
        fi

        echo "  Available configurations:"
        for config in "${gcloud_configs[@]}"; do
            local marker=""
            if [ "$config" = "$current_gcloud_config" ]; then
                marker=" (active)"
            fi
            echo "    - $config$marker"
        done
        echo ""

        if [ -n "$current_gcloud_config" ]; then
            local gcloud_conf="$PROFILES_DIR/$profile_name/$current_gcloud_config"
            if [ -f "$gcloud_conf" ] && _profile_validate_config_file "$gcloud_conf"; then
                # shellcheck source=/dev/null
                source "$gcloud_conf" 2>/dev/null || true
                echo "  Active configuration ($current_gcloud_config):"
                echo "    Account: ${GCLOUD_ACCOUNT:-not configured}"
                echo "    Project: ${GCLOUD_PROJECT:-not configured}"
                if [ -n "${GCLOUD_ACCOUNT_NAME:-}" ]; then
                    echo "    Account name: ${GCLOUD_ACCOUNT_NAME}"
                fi
                if [ -n "${GCLOUD_PROJECT_NAME:-}" ]; then
                    echo "    Project name: ${GCLOUD_PROJECT_NAME}"
                fi
            fi
        else
            echo "  No active GCloud configuration"
        fi
        echo ""
    else
        echo "GCloud/Firebase: no configuration available"
        echo ""
    fi

    if [ -f "$PROFILES_DIR/$profile_name/shell.conf" ]; then
        echo "Shell: configured"
        echo ""
    fi

    if [ -f "$PROFILES_DIR/$profile_name/env.conf" ]; then
        echo "Environment variables: configured"
        echo ""
    fi

    return 0
}

profile_switch() {
    local profile_name="$1"

    if [ -z "$profile_name" ]; then
        echo "Error: profile name not provided"
        return 1
    fi

    if ! _profile_validate_name "$profile_name"; then
        echo "Invalid profile name: only letters, numbers, hyphen and underscore are allowed"
        return 1
    fi

    if ! _profile_validate_path "$profile_name"; then
        echo "Path traversal attempt detected"
        return 1
    fi

    if ! _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' not found"
        echo ""
        echo "Available profiles:"
        profile_list
        return 1
    fi

    echo "Switching to profile: $profile_name"
    echo ""

    local current_profile
    current_profile=$(_profile_get_current)
    if [ -n "$current_profile" ] && [ "$current_profile" != "$profile_name" ]; then
        echo "Previous profile: $current_profile"
    fi

    if [ -f "$PROFILES_DIR/$profile_name/env.conf" ]; then
        echo "Environment variables will apply on the next shell"
    fi

    # Git and GCloud stay unchanged until profile_switch_git / profile_switch_gcloud.
    _profile_set_current "$profile_name"

    echo ""
    echo "Profile '$profile_name' activated successfully"
    echo ""

    return 0
}

profile_create() {
    local profile_name="$1"

    echo "Create new profile"
    echo ""

    if [ -z "$profile_name" ]; then
        if [ "${DOTFILES_YES:-0}" = 1 ]; then
            echo "Error: profile name not provided"
            return 1
        fi
        if ! _prompt_available; then
            return 1
        fi
        printf 'Profile name: ' >&2
        read -r profile_name

        if [ -z "$profile_name" ]; then
            echo "Error: profile name cannot be empty"
            return 1
        fi
    fi

    if ! _profile_validate_name "$profile_name"; then
        echo "Invalid profile name: only letters, numbers, hyphen and underscore are allowed"
        return 1
    fi

    if _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' already exists"
        return 1
    fi

    mkdir -p "$PROFILES_DIR/$profile_name"

    {
        echo "# Git configuration for profile: $profile_name"
        echo "GIT_NAME=\"\""
        echo "GIT_EMAIL=\"\""
        echo "# Signing key (SSH public key or GPG key ID)"
        echo "GIT_SIGNING_KEY=\"\""
        echo "# Or use GIT_GPG_KEY for older layouts"
        echo "# GIT_GPG_KEY=\"\""
        echo ""
        echo "# Optional GPG settings"
        echo "# GIT_GPG_PROGRAM=\"/usr/bin/gpg\""
        echo "# GIT_GPG_FORMAT=\"ssh\"  # or \"openpgp\""
        echo "# GIT_GPG_SSH_PROGRAM=\"/usr/local/bin/op-ssh-sign\""
        echo "# GIT_GPG_ALLOWED_SIGNERS=\"~/.config/git/allowed_signers\""
    } > "$PROFILES_DIR/$profile_name/git.conf"

    {
        echo "# Shell configuration for profile: $profile_name"
        echo "# Add profile-specific aliases and functions here"
    } > "$PROFILES_DIR/$profile_name/shell.conf"

    {
        echo "# Environment variables for profile: $profile_name"
        echo "# Add profile-specific environment variables here"
    } > "$PROFILES_DIR/$profile_name/env.conf"

    {
        echo "# GCloud/Firebase configuration for profile: $profile_name"
        echo "GCLOUD_ACCOUNT=\"\""
        echo "GCLOUD_ACCOUNT_NAME=\"\""
        echo ""
        echo "# Available projects for this account"
        echo "# Format: \"project_id|project_name\" or just \"project_id\""
        echo "# For a single project you may set: GCLOUD_PROJECT=\"project_id\""
        echo "GCLOUD_PROJECTS=("
        echo "    # \"project-id-1|Project Name 1\""
        echo "    # \"project-id-2|Project Name 2\""
        echo ")"
    } > "$PROFILES_DIR/$profile_name/gcloud.conf"

    echo "Profile '$profile_name' created successfully"
    echo ""
    echo "Edit the configuration files in: $PROFILES_DIR/$profile_name/"
    echo ""
    echo "Files created:"
    echo "  - git.conf      (Git configuration)"
    echo "  - shell.conf    (aliases and functions)"
    echo "  - env.conf      (environment variables)"
    echo "  - gcloud.conf   (GCloud/Firebase account, optional)"

    return 0
}

profile_edit() {
    local profile_name="$1"

    if [ -z "$profile_name" ]; then
        echo "Error: profile name not provided"
        return 1
    fi

    if ! _profile_validate_name "$profile_name"; then
        echo "Invalid profile name"
        return 1
    fi

    if ! _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' not found"
        return 1
    fi

    local editor="${EDITOR:-${VISUAL:-nano}}"
    local choice
    local profile_dir="$PROFILES_DIR/$profile_name"

    echo "Editing profile: $profile_name"
    echo ""

    if ! choice=$(_choose "Choose a file to edit" "git.conf" "shell.conf" "env.conf" "gcloud.conf" "All"); then
        echo "Error: no file selected"
        return 1
    fi

    case "$choice" in
        git.conf) $editor "$profile_dir/git.conf" ;;
        shell.conf) $editor "$profile_dir/shell.conf" ;;
        env.conf) $editor "$profile_dir/env.conf" ;;
        gcloud.conf) $editor "$profile_dir/gcloud.conf" ;;
        All)
            $editor "$profile_dir/git.conf"
            $editor "$profile_dir/shell.conf"
            $editor "$profile_dir/env.conf"
            $editor "$profile_dir/gcloud.conf"
            ;;
        *)
            echo "Error: invalid option"
            return 1
            ;;
    esac

    return 0
}

profile_delete() {
    local profile_name="$1"

    if [ -z "$profile_name" ]; then
        echo "Error: profile name not provided"
        return 1
    fi

    if ! _profile_validate_name "$profile_name"; then
        echo "Invalid profile name: only letters, numbers, hyphen and underscore are allowed"
        return 1
    fi

    if ! _profile_validate_path "$profile_name"; then
        echo "Path traversal attempt detected"
        return 1
    fi

    if ! _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' not found"
        return 1
    fi

    local current_profile
    current_profile=$(_profile_get_current)

    if [ "$profile_name" = "$current_profile" ]; then
        echo "Cannot remove the active profile: $profile_name"
        echo "   Switch to another profile first"
        return 1
    fi

    echo "Removing profile: $profile_name"
    echo ""

    if _confirm "Remove profile '$profile_name'? This cannot be undone."; then
        local profile_path="${PROFILES_DIR:?}/$profile_name"
        rm -rf "$profile_path"
        echo "Profile '$profile_name' removed"
        return 0
    else
        echo "Operation cancelled"
        return 1
    fi
}

profile_export() {
    local profile_name="$1"
    local output_file="${2:-$profile_name-$(date +%Y%m%d-%H%M%S).tar.gz}"

    if [ -z "$profile_name" ]; then
        echo "Error: profile name not provided"
        return 1
    fi

    if ! _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' not found"
        return 1
    fi

    echo "Exporting profile: $profile_name"

    if tar -czf "$output_file" -C "$PROFILES_DIR" "$profile_name"; then
        echo "Profile exported to: $output_file"
        return 0
    else
        echo "Error exporting profile"
        return 1
    fi
}

profile_import() {
    local input_file="$1"

    if [ -z "$input_file" ]; then
        echo "Error: file not provided"
        return 1
    fi

    if [ ! -f "$input_file" ]; then
        echo "File not found: $input_file"
        return 1
    fi

    echo "Importing profile from: $input_file"

    local temp_dir
    temp_dir=$(mktemp -d)

    if ! tar -xzf "$input_file" -C "$temp_dir"; then
        echo "Error extracting archive"
        rm -rf "$temp_dir"
        return 1
    fi

    local profile_dirs
    profile_dirs=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d)
    local count
    count=$(echo "$profile_dirs" | wc -l)

    if [ "$count" -ne 1 ]; then
        echo "Invalid archive: must contain exactly one profile"
        rm -rf "$temp_dir"
        return 1
    fi

    local profile_name
    profile_name=$(basename "$profile_dirs")

    if ! _profile_validate_name "$profile_name"; then
        echo "Invalid profile name in archive: only letters, numbers, hyphen and underscore are allowed"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! _profile_validate_path "$profile_name"; then
        echo "Path traversal attempt detected in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    if _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' already exists"
        if _confirm "Overwrite profile '$profile_name'?"; then
            local profile_path="${PROFILES_DIR:?}/$profile_name"
            rm -rf "$profile_path"
        else
            echo "Operation cancelled"
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    mv "$profile_dirs" "${PROFILES_DIR:?}/$profile_name"
    rm -rf "$temp_dir"

    echo "Profile '$profile_name' imported successfully"
    return 0
}

profile_validate() {
    local profile_name="$1"

    if [ -z "$profile_name" ]; then
        echo "Error: profile name not provided"
        return 1
    fi

    if ! _profile_validate_name "$profile_name"; then
        echo "Invalid profile name"
        return 1
    fi

    if ! _profile_exists "$profile_name"; then
        echo "Profile '$profile_name' not found"
        return 1
    fi

    local errors=0

    if [ -f "$PROFILES_DIR/$profile_name/git.conf" ]; then
        # shellcheck source=/dev/null
        source "$PROFILES_DIR/$profile_name/git.conf"
        if [ -z "${GIT_NAME:-}" ] || [ -z "${GIT_EMAIL:-}" ]; then
            echo "git.conf: GIT_NAME or GIT_EMAIL not configured"
            ((errors++)) || true
        fi
    fi

    if [ -f "$PROFILES_DIR/$profile_name/gcloud.conf" ]; then
        # shellcheck source=/dev/null
        source "$PROFILES_DIR/$profile_name/gcloud.conf"
        if [ -z "${GCLOUD_ACCOUNT:-}" ]; then
            echo "gcloud.conf: GCLOUD_ACCOUNT not configured"
            ((errors++)) || true
        fi
    fi

    if [ $errors -eq 0 ]; then
        echo "Profile '$profile_name' is valid"
        return 0
    else
        echo "Profile '$profile_name' has $errors problem(s)"
        return 1
    fi
}

profile_load() {
    local profile_name
    profile_name=$(_profile_get_current)

    if [ -z "$profile_name" ]; then
        return 0
    fi

    if ! _profile_exists "$profile_name"; then
        return 1
    fi

    local env_conf="$PROFILES_DIR/$profile_name/env.conf"
    if [ -f "$env_conf" ]; then
        if _profile_validate_config_file "$env_conf"; then
            # shellcheck source=/dev/null
            source "$env_conf"
        else
            echo "env.conf contains potentially dangerous commands, skipping load"
        fi
    fi

    local shell_conf="$PROFILES_DIR/$profile_name/shell.conf"
    if [ -f "$shell_conf" ]; then
        if _profile_validate_config_file "$shell_conf"; then
            # shellcheck source=/dev/null
            source "$shell_conf"
        else
            echo "shell.conf contains potentially dangerous commands, skipping load"
        fi
    fi

    return 0
}
