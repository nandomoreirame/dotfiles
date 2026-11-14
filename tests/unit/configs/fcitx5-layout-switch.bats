#!/usr/bin/env bats

# fcitx5 owns the layout switch: with it running, its keyboard IM decides what
# apps receive and Noctalia's bar widget reads the layout from it, so a niri
# xkb group toggle changes neither.
#
# Run:
#   ./tests/run-tests unit/configs/fcitx5-layout-switch.bats

load '../../bats/helpers/setup'

FCITX_CONFIG="$PROJECT_ROOT/configs/fcitx5/config"

@test "fcitx5 cycles input methods with Alt+Space" {
    run sed -n '/^\[Hotkey\/EnumerateForwardKeys\]/,/^\[/p' "$FCITX_CONFIG"
    [[ "$output" == *'0=Alt+space'* ]]
}

@test "fcitx5 shares the active layout across windows" {
    run sed -n '/^\[Behavior\]/,/^\[/p' "$FCITX_CONFIG"
    [[ "$output" == *'ShareInputState=All'* ]]
}


