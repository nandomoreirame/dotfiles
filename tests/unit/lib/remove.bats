#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
}

@test "pacman remove without names fails" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" pacman:remove
    [ "$status" -ne 0 ]
    [[ "$output" == *"name"* ]]
}

@test "aur remove without names fails" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" aur:remove
    [ "$status" -ne 0 ]
    [[ "$output" == *"name"* ]]
}

@test "flatpak remove without names fails" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" flatpak:remove
    [ "$status" -ne 0 ]
    [[ "$output" == *"name"* ]]
}
