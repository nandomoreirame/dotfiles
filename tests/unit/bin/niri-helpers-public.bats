#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

@test "every niri helper is executable and passes shellcheck" {
    for f in "$ROOT"/bin/utils/niri-*; do
        [ -x "$f" ]
        shellcheck -x "$f"
    done
}

@test "niri helpers carry no personal string" {
    run grep -nE "jane|/home/|rdo-solo|homelab|LG TV" "$ROOT"/bin/utils/niri-*
    [ "$status" -ne 0 ]
}

@test "niri helpers are in english" {
    run grep -nE "[áàâãéêíóôõúç]|\b(não|erro|arquivo)\b" "$ROOT"/bin/utils/niri-*
    [ "$status" -ne 0 ]
}

@test "the TV-specific and jack helpers are not public" {
    [ ! -e "$ROOT/bin/utils/niri-hdmi-automode" ]
    [ ! -e "$ROOT/bin/utils/audio-jack-autoswitch" ]
}
