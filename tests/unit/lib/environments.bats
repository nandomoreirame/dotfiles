#!/usr/bin/env bats

# Tests for lib/environments.sh
#
# Run:
#   ./tests/run-tests unit/lib/environments.bats

load '../../bats/helpers/setup'

setup() {
    TEST_TMP="$(temp_make)"
}

teardown() {
    temp_del "$TEST_TMP"
}

@test "DOTFILES_IS_ARCH=true when os-release has ID=arch" {
    local fake_os_release="$TEST_TMP/os-release"
    printf 'ID=arch\nID_LIKE=\nNAME=Arch Linux\n' > "$fake_os_release"

    run bash -c "
        DOTFILES_OS_RELEASE_FILE='$fake_os_release'
        source '$PROJECT_ROOT/lib/environments.sh'
        echo \"\$DOTFILES_IS_ARCH\"
    "
    assert_success
    assert_output "true"
}

@test "DOTFILES_IS_LINUX=true on Arch Linux" {
    local fake_os_release="$TEST_TMP/os-release"
    printf 'ID=arch\n' > "$fake_os_release"

    run bash -c "
        DOTFILES_OS_RELEASE_FILE='$fake_os_release'
        source '$PROJECT_ROOT/lib/environments.sh'
        echo \"\$DOTFILES_IS_LINUX\"
    "
    assert_success
    assert_output "true"
}

@test "DOTFILES_IS_ARCH=false on a non-Arch distribution" {
    local fake_os_release="$TEST_TMP/os-release"
    printf 'ID=ubuntu\nID_LIKE=debian\n' > "$fake_os_release"

    run bash -c "
        DOTFILES_OS_RELEASE_FILE='$fake_os_release'
        source '$PROJECT_ROOT/lib/environments.sh'
        echo \"\$DOTFILES_IS_ARCH\"
    "
    assert_success
    assert_output "false"
}

@test "DOTFILES_IS_ARCH=false when os-release is absent" {
    run bash -c "
        DOTFILES_OS_RELEASE_FILE='/tmp/nonexistent-os-release-file'
        source '$PROJECT_ROOT/lib/environments.sh'
        echo \"\$DOTFILES_IS_ARCH\"
    "
    assert_success
    assert_output "false"
}

@test "DOTFILES_IS_ARCH=true when ID_LIKE contains arch" {
    local fake_os_release="$TEST_TMP/os-release"
    printf 'ID=endeavouros\nID_LIKE=arch\n' > "$fake_os_release"

    run bash -c "
        DOTFILES_OS_RELEASE_FILE='$fake_os_release'
        source '$PROJECT_ROOT/lib/environments.sh'
        echo \"\$DOTFILES_IS_ARCH\"
    "
    assert_success
    assert_output "true"
}
