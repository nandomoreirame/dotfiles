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

@test "_profile_validate_config_file: rejects a missing file" {
    run _profile_validate_config_file "$TEST_DIR/nonexistent.conf"
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
