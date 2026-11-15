#!/usr/bin/env bats

# niri window decorations follow the Terminal Noir palette
# (configs/noctalia/palettes/Terminal Noir.json).
#
# Run:
#   ./tests/run-tests unit/configs/niri-theme.bats

load '../../bats/helpers/setup'

NIRI_CONFIG="$PROJECT_ROOT/configs/niri/config.kdl"

# Print the body of a `<name> {` block inside layout.
layout_block() {
    sed -n "/^layout {/,/^}/p" "$NIRI_CONFIG" | sed -n "/^    $1 {/,/^    }/p"
}

@test "focus ring is the solid primary amber" {
    run layout_block focus-ring
    [[ "$output" == *'active-color "#f5a623"'* ]]
    [[ "$output" == *'inactive-color "#3f3f46"'* ]]
    [[ "$output" == *'urgent-color "#ffb7b0"'* ]]
}

@test "border is the same hairline on every window, pink when urgent" {
    run layout_block border
    [[ "$output" == *'width 1'* ]]
    [[ "$output" == *'active-color "#222226"'* ]]
    [[ "$output" == *'inactive-color "#222226"'* ]]
    [[ "$output" == *'urgent-color "#ffb7b0"'* ]]
}

@test "insert hint is a translucent primary amber" {
    run layout_block insert-hint
    [[ "$output" == *'color "#f5a62380"'* ]]
}

@test "the niri config still validates" {
    if ! command -v niri >/dev/null 2>&1; then
        skip "niri binary not available"
    fi
    # Include siblings so validate can resolve include "monitor.kdl" / private.kdl
    d="$BATS_TEST_TMPDIR/niri"; mkdir -p "$d"; cp "$PROJECT_ROOT"/configs/niri/*.kdl "$d/"
    run niri validate -c "$d/config.kdl"
    assert_success
}

@test "layout uses 4 px gaps and no struts, so windows reach the screen edges" {
    run sed -n "/^layout {/,/^}/p" "$NIRI_CONFIG"
    [[ "$output" == *"    gaps 4"* ]]
    [[ "$output" != *"struts"* ]]
}
