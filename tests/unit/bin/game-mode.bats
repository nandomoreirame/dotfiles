#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    FAKE="$BATS_TEST_TMPDIR/fake"; CALLS="$BATS_TEST_TMPDIR/calls"; mkdir -p "$FAKE"; : > "$CALLS"
    for c in pkill kill pgrep; do printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$c" "$CALLS" > "$FAKE/$c"; chmod +x "$FAKE/$c"; done
}

@test "game-mode uses GAME_MODE_APPS" {
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="$FAKE:/usr/bin:/bin" GAME_MODE_APPS="alpha beta" bash "$ROOT/bin/utils/game-mode" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* && "$output" == *"beta"* ]]
}

@test "game-mode default list names no personal app" {
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="$FAKE:/usr/bin:/bin" bash "$ROOT/bin/utils/game-mode" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"rdo"* && "$output" != *"obs-live"* ]]
}

@test "game-mode is in english and carries no personal string" {
    run grep -nE "jane|/home/|homelab|[áàâãéêíóôõúç]" "$ROOT/bin/utils/game-mode"
    [ "$status" -ne 0 ]
}
