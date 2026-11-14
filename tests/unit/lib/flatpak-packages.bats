#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME"
    printf '#!/bin/sh\necho "flatpak $*" >> "%s"\n[ "$1" = "info" ] || exit 0\nshift\n[ "$1" = "--" ] && shift\n[ "$1" = "installed.app" ] && exit 0\nexit 1\n' "$LOG" > "$STUBS/flatpak"
    chmod +x "$STUBS/flatpak"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$DOTFILES_PRIVATE"
    : > "$LOG"
}

run_fp() {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" TERM=xterm-256color "$@" bash -c "source '$ROOT/lib/flatpak-packages.sh'; $PCMD"
}

@test "flatpak install skips installed packages" {
    PCMD='_flatpak_packages "installed.app new.app"'
    run_fp DOTFILES_YES=1
    [ "$status" -eq 0 ]
    grep -q "flatpak install .* new.app" "$LOG"
    ! grep -q "flatpak install .* installed.app" "$LOG"
}

@test "flatpak dry-run prints the commands and installs nothing" {
    PCMD='_flatpak_packages "new.app"'
    run_fp DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    ! grep -q "^flatpak install" "$LOG"
}

@test "flatpak reports a failing package and continues" {
    printf '#!/bin/sh\necho "flatpak $*" >> "%s"\n[ "$1" = "info" ] && exit 1\ncase "$*" in *bad.app*) exit 1;; esac\nexit 0\n' "$LOG" > "$STUBS/flatpak"
    PCMD='_flatpak_packages "bad.app good.app"'
    run_fp DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"bad.app"* ]]
    grep -q "good.app" "$LOG"
}

@test "flatpak empty argument uses the public list" {
    PCMD='_flatpak_packages ""'
    run_fp DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Flatseal"* ]]
    [[ "$output" != *"Slack"* ]]
}

@test "flatpak remove asks for confirmation" {
    PCMD='_flatpak_remove "new.app" </dev/null'
    run_fp
    [ "$status" -ne 0 ]
    ! grep -q "flatpak uninstall" "$LOG"
}

@test "hostile flatpak name is rejected" {
    PCMD='_flatpak_packages "--overwrite=*"'
    run_fp DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid package name"* ]]
    ! grep -q "flatpak install" "$LOG"
}

@test "flatpak install passes -- before the package name" {
    PCMD='_flatpak_packages "new.app"'
    run_fp DOTFILES_YES=1
    [ "$status" -eq 0 ]
    grep -q "flatpak install -y flathub -- new.app" "$LOG"
}
