#!/usr/bin/env bats


load '../../bats/helpers/setup'

setup() {
    source "$PROJECT_ROOT/lib/environments.sh"
    source "$PROJECT_ROOT/lib/validation.sh"
    source "$PROJECT_ROOT/lib/cli-parser.sh"
    TEST_DIR="$(temp_make)"
}

teardown() {
    temp_del "$TEST_DIR"
}


@test "_cli_error: prints an error message" {
    run _cli_error "Test error message"
    assert_success
    assert_output --partial "Error"
    assert_output --partial "Test error message"
}


@test "_cli_warn: prints a warning message" {
    run _cli_warn "Test warning message"
    assert_success
    assert_output --partial "Test warning message"
}


@test "_cli_info: prints an info message" {
    run _cli_info "Test info message"
    assert_success
    assert_output --partial "Test info message"
}


@test "_cli_success: prints a success message" {
    run _cli_success "Test success message"
    assert_success
    assert_output --partial "Test success message"
}


@test "_version: prints the dotfiles version" {
    run _version
    assert_success
    assert_output --partial "dotfiles v"
    assert_output --partial "Environment manager"
}

@test "_version: includes system information" {
    run _version
    assert_success
    assert_output --partial "OS:"
    assert_output --partial "Path:"
}


@test "_links_handler: shows help with --help" {
    run _links_handler "--help"
    assert_success
    assert_output --partial "dotfiles links"
    assert_output --partial "--all"
    assert_output --partial "--files"
    assert_output --partial "--paths"
}

@test "_links_handler: shows help with -h" {
    run _links_handler "-h"
    assert_success
    assert_output --partial "dotfiles links"
}

@test "_links_handler: rejects unknown options" {
    run _links_handler "--invalid-option"
    assert_failure
    assert_output --partial "Unknown"
}


@test "_dispatch: rejects unknown modules" {
    run _dispatch "invalid_module" "action"
    assert_failure
    assert_output --partial "Unknown"
    assert_output --partial "Available modules"
}



@test "_parse_command: shows help with --help" {
    _help() { echo "HELP_OUTPUT"; }
    export -f _help

    run _parse_command "--help"
    assert_success
}

@test "_parse_command: shows help with -h" {
    _help() { echo "HELP_OUTPUT"; }
    export -f _help

    run _parse_command "-h"
    assert_success
}

@test "_parse_command: prints version with --version" {
    run _parse_command "--version"
    assert_success
    assert_output --partial "dotfiles v"
}

@test "_parse_command: prints version with -v" {
    run _parse_command "-v"
    assert_success
    assert_output --partial "dotfiles v"
}

@test "_parse_command: rejects unknown commands" {
    run _parse_command "unknown_command"
    assert_failure
    assert_output --partial "Unknown"
}



@test "_parse_command: parses the links module" {
    run _parse_command "links" "--help"
    assert_success
    assert_output --partial "dotfiles links"
}


