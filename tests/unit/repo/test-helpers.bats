#!/usr/bin/env bats
load '../../bats/helpers/setup'

@test "PROJECT_ROOT and DOTFILES point at the repository root" {
    [ -f "$PROJECT_ROOT/tests/run-tests" ]
    [ "$DOTFILES" = "$PROJECT_ROOT" ]
}

@test "temp_make creates a directory and temp_del removes it" {
    d="$(temp_make)"
    [ -d "$d" ]
    temp_del "$d"
    [ ! -e "$d" ]
}

@test "temp_del works when TMPDIR is customised" {
    export TMPDIR="$BATS_TEST_TMPDIR"
    d="$(temp_make)"
    [ -d "$d" ]
    temp_del "$d"
    [ ! -e "$d" ]
}

@test "temp_del refuses a path that temp_make did not create" {
    keep="$BATS_TEST_TMPDIR/keep"
    mkdir -p "$keep"
    temp_del "$keep"
    [ -d "$keep" ]
}

@test "mock_command puts a stub first on PATH and mock_cleanup removes it" {
    mock_init
    mock_command fakecmd 'echo stubbed'
    run fakecmd
    [ "$output" = "stubbed" ]
    mock_cleanup
    run command -v fakecmd
    [ "$status" -ne 0 ]
}

@test "mock_command can fail on demand" {
    mock_init
    mock_command fakecmd 'exit 3'
    run fakecmd
    [ "$status" -eq 3 ]
    mock_cleanup
}
