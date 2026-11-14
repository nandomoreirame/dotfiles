#!/usr/bin/env bats

# Cursor runs on electron40 and its CLI warns about any flag missing from the
# VS Code option list. The Arch wrapper prefers electron40-flags.conf over the
# shared electron-flags.conf, so that file keeps --force-dark-mode away from
# Cursor while every other Electron app still gets it.
#
# Run:
#   ./tests/run-tests unit/configs/electron-flags.bats

load '../../bats/helpers/setup'

CONFIGS="$PROJECT_ROOT/configs"

@test "electron40-flags.conf exists so the wrapper skips the shared fallback" {
    [ -f "$CONFIGS/electron40-flags.conf" ]
}

@test "electron40-flags.conf does not enable force-dark-mode" {
    run grep -Eq '^[[:space:]]*--force-dark-mode' "$CONFIGS/electron40-flags.conf"
    [ "$status" -ne 0 ]
}

@test "electron-flags.conf still forces dark mode for the other Electron apps" {
    grep -Fqx -- '--force-dark-mode' "$CONFIGS/electron-flags.conf"
}

