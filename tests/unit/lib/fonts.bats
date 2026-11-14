#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME/.fonts/keep" "$DOTFILES_PRIVATE"
    for c in pacman sudo curl wget unzip rm; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\nexit 0\n' "$c" "$LOG" > "$STUBS/$c"
    done
    chmod +x "$STUBS"/*
    : > "$LOG"
}

@test "fonts install uses the pacman group and downloads nothing" {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" DOTFILES_YES=1 TERM=xterm-256color bash -c "source '$ROOT/lib/fonts.sh'; _install_fonts"
    [ "$status" -eq 0 ]
    grep -q "pacman .*ttf-meslo-nerd" "$LOG"
    ! grep -qE "^(curl|wget|unzip|rm) " "$LOG"
    [ -d "$HOME/.fonts/keep" ]
}

@test "fonts code has no download or deletion" {
    run grep -nE "curl|wget|unzip|rm -rf|releases/latest|DankMono" "$ROOT/lib/fonts.sh"
    [ "$status" -ne 0 ]
}
