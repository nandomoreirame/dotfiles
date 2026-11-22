#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME"
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\n[ "$1" = "-Q" ] || exit 0\nshift\n[ "$1" = "--" ] && shift\n[ "$1" = "installed-pkg" ] && exit 0\nexit 1\n' "$LOG" > "$STUBS/pacman"
    printf '#!/bin/sh\necho "yay $*" >> "%s"\nexit 0\n' "$LOG" > "$STUBS/yay"
    chmod +x "$STUBS/pacman" "$STUBS/yay"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$DOTFILES_PRIVATE"
    : > "$LOG"
}

run_aur() {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" TERM=xterm-256color "$@" bash -c "source '$ROOT/lib/aur-packages.sh'; $PCMD"
}

@test "aur helper prefers yay" {
    PCMD='_get_aur_helper'
    run_aur
    [ "$output" = "yay" ]
}

@test "aur helper falls back to paru" {
    rm -f "$STUBS/yay"
    printf '#!/bin/sh\necho paru\n' > "$STUBS/paru"
    chmod +x "$STUBS/paru"
    PCMD='_get_aur_helper'
    run_aur
    [ "$output" = "paru" ]
}

@test "aur install fails clearly without a helper" {
    rm -f "$STUBS/yay" "$STUBS/paru"
    PCMD='_aur_packages "new-pkg"'
    # Isolate from system yay/paru (this host has /bin/paru). Use absolute bash
    # because env searches PATH for the command name.
    run env -i HOME="$HOME" PATH="$STUBS" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" TERM=dumb DOTFILES_YES=1 /usr/bin/bash -c "source '$ROOT/lib/aur-packages.sh'; $PCMD"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No AUR helper"* ]]
    [[ "$output" == *"yay"* ]]
    [[ "$output" == *"paru"* ]]
}

@test "aur install skips installed packages" {
    PCMD='_aur_packages "installed-pkg new-pkg"'
    run_aur DOTFILES_YES=1
    [ "$status" -eq 0 ]
    grep -q "yay -S --noconfirm --needed -- new-pkg" "$LOG"
    ! grep -q "yay -S --noconfirm --needed -- installed-pkg" "$LOG"
}

@test "aur dry-run prints the commands and calls no helper install" {
    PCMD='_aur_packages "new-pkg"'
    run_aur DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    ! grep -q "^yay -S" "$LOG"
}

@test "aur reports a failing package and continues" {
    printf '#!/bin/sh\necho "yay $*" >> "%s"\ncase "$*" in *bad-pkg*) exit 1;; esac\nexit 0\n' "$LOG" > "$STUBS/yay"
    PCMD='_aur_packages "bad-pkg good-pkg"'
    run_aur DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"bad-pkg"* ]]
    grep -q "good-pkg" "$LOG"
}

@test "aur empty argument uses the public list" {
    PCMD='_aur_packages ""'
    run_aur DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"google-chrome"* ]]
    [[ "$output" != *"cursor-bin"* ]]
}

@test "aur remove asks for confirmation" {
    PCMD='_aur_remove "new-pkg" </dev/null'
    run_aur
    [ "$status" -ne 0 ]
    ! grep -q "yay -R" "$LOG"
}

@test "hostile aur package name is rejected" {
    PCMD='_aur_packages "--overwrite=*"'
    run_aur DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid package name"* ]]
    ! grep -q "yay -S" "$LOG"
}

@test "an installed variant without -bin counts as installed" {
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\n[ "$1" = "-Q" ] || exit 0\nshift\n[ "$1" = "--" ] && shift\n[ "$1" = "heroic" ] && exit 0\nexit 1\n' "$LOG" > "$STUBS/pacman"
    PCMD='_aur_packages "heroic-bin"'
    run_aur DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"heroic-bin (installed as heroic)"* ]]
    run grep -q "yay -S" "$LOG"
    [ "$status" -ne 0 ]
}

@test "an installed -git variant counts as installed" {
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\n[ "$1" = "-Q" ] || exit 0\nshift\n[ "$1" = "--" ] && shift\n[ "$1" = "tool-git" ] && exit 0\nexit 1\n' "$LOG" > "$STUBS/pacman"
    PCMD='_aur_packages "tool-bin"'
    run_aur DOTFILES_YES=1
    [ "$status" -eq 0 ]
    run grep -q "yay -S" "$LOG"
    [ "$status" -ne 0 ]
}

@test "a failed AUR package is recorded for the install summary" {
    printf '#!/bin/sh\necho "yay $*" >> "%s"\nexit 1\n' "$LOG" > "$STUBS/yay"
    PCMD='_aur_packages "broken-pkg"; printf "RECORDED=%s\n" "${DOTFILES_FAILURES[*]}"'
    run_aur DOTFILES_YES=1
    [[ "$output" == *"RECORDED=AUR: broken-pkg"* ]]
}
