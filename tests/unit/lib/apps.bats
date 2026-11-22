#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$HOME" "$DOTFILES_PRIVATE"
}

@test "packages install --manager pacman previews with --dry-run" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" bash "$ROOT/bin/dotfiles" packages install --manager pacman --group fonts --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"ttf-meslo-nerd"* ]]
}

@test "packages install runs every manager in order" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" bash "$ROOT/bin/dotfiles" packages install --dry-run --yes
    last=0
    for kind in "Selected pacman" "Selected AUR" "Selected Flatpak" "npm" "Selected shell"; do
        n="$(printf '%s\n' "$output" | grep -n "$kind" | head -1 | cut -d: -f1)"
        [ -n "$n" ] || { echo "missing: $kind"; false; }
        [ "$n" -gt "$last" ]
        last="$n"
    done
}

@test "the interactive flag is not an option" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" packages install --manager pacman -i
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown option: -i"* ]]
}

@test "remove needs explicit names" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" packages remove --manager pacman
    [ "$status" -ne 0 ]
    [[ "$output" == *"name"* ]]
}

@test "the packages help lists every manager and no -i flag" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" bash "$ROOT/bin/dotfiles" packages --help
    for m in pacman aur flatpak node sh; do
        [[ "$output" == *"$m"* ]]
    done
    [[ "$output" != *" -i"* ]]
}
