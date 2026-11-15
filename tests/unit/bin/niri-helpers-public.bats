#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

desktop_helpers() {
    # Public desktop helpers covered by the language/privacy lint.
    printf '%s\n' "$ROOT"/bin/utils/niri-* \
        "$ROOT"/bin/utils/nocta \
        "$ROOT"/bin/utils/nocta-hold \
        "$ROOT"/bin/utils/noctalia-restart \
        "$ROOT"/bin/utils/noctalia-plugins-link \
        "$ROOT"/bin/utils/webapp-* \
        "$ROOT"/bin/utils/game-mode
}

@test "every niri helper is executable and passes shellcheck" {
    for f in "$ROOT"/bin/utils/niri-*; do
        [ -x "$f" ]
        shellcheck -x "$f"
    done
}

@test "desktop helpers nocta webapp and game-mode pass shellcheck" {
    for f in "$ROOT"/bin/utils/nocta "$ROOT"/bin/utils/nocta-hold \
        "$ROOT"/bin/utils/noctalia-restart "$ROOT"/bin/utils/noctalia-plugins-link \
        "$ROOT"/bin/utils/webapp-* "$ROOT"/bin/utils/game-mode; do
        [ -x "$f" ]
        shellcheck -x "$f"
    done
}

@test "desktop helpers carry no personal string" {
    # shellcheck disable=SC2046
    run grep -nE "jane|/home/|rdo-solo|homelab|LG TV" $(desktop_helpers)
    [ "$status" -ne 0 ]
}

@test "desktop helpers are in english" {
    # shellcheck disable=SC2046
    run grep -nE "[áàâãéêíóôõúç]|\b(não|erro|arquivo|recurso|obrigatorio|inativo|uso:)\b" $(desktop_helpers)
    [ "$status" -ne 0 ]
}

@test "the TV-specific and jack helpers are not public" {
    [ ! -e "$ROOT/bin/utils/niri-hdmi-automode" ]
    [ ! -e "$ROOT/bin/utils/audio-jack-autoswitch" ]
}
