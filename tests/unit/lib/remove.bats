#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
}

remove_without_names() {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" packages remove --manager "$1"
    [ "$status" -ne 0 ]
    [[ "$output" == *"name"* ]]
}

@test "pacman remove without names fails" { remove_without_names pacman; }
@test "aur remove without names fails" { remove_without_names aur; }
@test "flatpak remove without names fails" { remove_without_names flatpak; }
@test "node remove without names fails" { remove_without_names node; }
