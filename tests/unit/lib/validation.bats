#!/usr/bin/env bats


load '../../bats/helpers/setup'

setup() {
    source "$PROJECT_ROOT/lib/validation.sh"
    TEST_DIR="$(temp_make)"
}

teardown() {
    temp_del "$TEST_DIR"
}


@test "validate_args_count: accepts sufficient arguments" {
    run validate_args_count 2 3 'test-script'
    assert_success
}

@test "validate_args_count: rejects insufficient arguments" {
    run validate_args_count 3 2 'test-script'
    assert_failure
}

@test "validate_args_count: rejects zero arguments when one is required" {
    run validate_args_count 1 0 'test-script'
    assert_failure
}


@test "validate_not_empty: accepts nonempty strings" {
    run validate_not_empty 'value' 'test-name'
    assert_success
}

@test "validate_not_empty: rejects empty strings" {
    run validate_not_empty '' 'test-name'
    assert_failure
    assert_output --partial "cannot be empty"
}


@test "validate_command: accepts existing commands" {
    run validate_command 'bash'
    assert_success
}

@test "validate_command: rejects absent commands" {
    run validate_command 'nonexistent-command-xyz-12345'
    assert_failure
    assert_output --partial "not found"
}


@test "validate_directory: accepts existing directories" {
    mkdir -p "$TEST_DIR/test-dir"
    run validate_directory "$TEST_DIR/test-dir"
    assert_success
}

@test "validate_directory: rejects absent directories" {
    run validate_directory "$TEST_DIR/nonexistent-dir"
    assert_failure
}


@test "validate_file: accepts existing files" {
    touch "$TEST_DIR/test-file"
    run validate_file "$TEST_DIR/test-file"
    assert_success
}

@test "validate_file: rejects absent files" {
    run validate_file "$TEST_DIR/nonexistent-file"
    assert_failure
}


@test "validate_pattern: accepts semantic versions" {
    run validate_pattern "1.0.0" "^[0-9]+\.[0-9]+\.[0-9]+$" "version"
    assert_success
}

@test "validate_pattern: rejects invalid versions" {
    run validate_pattern "1.0" "^[0-9]+\.[0-9]+\.[0-9]+$" "version"
    assert_failure
}

@test "validate_pattern: accepts valid email" {
    run validate_pattern "test@example.com" "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" "email"
    assert_success
}


@test "validate_option: accepts a valid option" {
    run validate_option "start" "start" "finish" "list"
    assert_success
}

@test "validate_option: rejects invalid options" {
    run validate_option "invalid" "start" "finish" "list"
    assert_failure
}

@test "validate_option: accepts any valid option" {
    run validate_option "finish" "start" "finish" "list"
    assert_success
}

@test "validation has no macOS or Debian branch" {
    run grep -nEi 'macos|darwin|debian|homebrew|brew ' "$PROJECT_ROOT/lib/validation.sh"
    [ "$status" -eq 1 ]
}
