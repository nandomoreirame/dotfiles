#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME"
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\n[ "$1" = "-Q" ] || exit 0\nshift\n[ "$1" = "--" ] && shift\n[ "$1" = "installed-pkg" ] && exit 0\nexit 1\n' "$LOG" > "$STUBS/pacman"
    printf '#!/bin/sh\necho "sudo $*" >> "%s"\nexec "$@"\n' "$LOG" > "$STUBS/sudo"
    chmod +x "$STUBS/pacman" "$STUBS/sudo"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$DOTFILES_PRIVATE"
    : > "$LOG"
}

run_pm() {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" TERM=xterm-256color "$@" bash -c "source '$ROOT/lib/pacman-packages.sh'; $PCMD"
}

@test "pacman install skips installed packages" {
    PCMD='_pacman_packages "installed-pkg new-pkg"'
    run_pm DOTFILES_YES=1
    [ "$status" -eq 0 ]
    grep -q "pacman -S.* new-pkg" "$LOG"
    ! grep -q "pacman -S.* installed-pkg" "$LOG"
}

@test "pacman dry-run prints the commands and calls no sudo" {
    PCMD='_pacman_packages "new-pkg"'
    run_pm DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"new-pkg"* ]]
    ! grep -q "^sudo" "$LOG"
}

@test "pacman reports a failing package and continues" {
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\ncase "$*" in *bad-pkg*) exit 1;; esac\n[ "$1" = "-Q" ] && exit 1\nexit 0\n' "$LOG" > "$STUBS/pacman"
    # -Q still fails for every package so both attempt install
    PCMD='_pacman_packages "bad-pkg good-pkg"'
    run_pm DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"bad-pkg"* ]]
    grep -q "good-pkg" "$LOG"
}

@test "a group selects packages from the list" {
    PCMD='_pacman_packages "$(_package_list pacman fonts | tr "\n" " ")"'
    run_pm DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [[ "$output" == *"ttf-meslo-nerd"* ]]
}

@test "pacman remove asks for confirmation" {
    PCMD='_pacman_remove "new-pkg" </dev/null'
    run_pm
    [ "$status" -ne 0 ]
    ! grep -q "pacman -R" "$LOG"
}

@test "pacman empty argument uses the public list" {
    PCMD='_pacman_packages ""'
    run_pm DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"bat"* ]]
    [[ "$output" == *"[dry-run]"* ]]
}

@test "pacman list has no personal picks" {
    PCMD='_pacman_packages ""'
    run_pm DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [[ "$output" != *"discord"* ]]
    [[ "$output" != *"obsidian"* ]]
}

@test "hostile package name is rejected" {
    PCMD='_pacman_packages "--overwrite=*"'
    run_pm DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid package name"* ]]
    ! grep -q "pacman -S" "$LOG"
}

@test "pacman install passes -- before the package name" {
    PCMD='_pacman_packages "new-pkg"'
    run_pm DOTFILES_YES=1
    [ "$status" -eq 0 ]
    grep -q "pacman -S --noconfirm --needed -- new-pkg" "$LOG"
}
