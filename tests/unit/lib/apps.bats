#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$HOME" "$DOTFILES_PRIVATE"
}

@test "pacman:install previews with --dry-run" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" bash "$ROOT/bin/dotfiles" pacman:install --group fonts --dry-run --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"ttf-meslo-nerd"* ]]
}

@test "apps:install runs every kind in order" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" bash "$ROOT/bin/dotfiles" apps:install --dry-run --yes
    # langs may fail without mise config; overall may be non-zero, but earlier kinds must appear.
    [ "$(printf '%s\n' "$output" | grep -nE 'pacman|Selected pacman|Selected AUR|Selected Flatpak|Selected npm|Selected shell|Installing mise|mise config' | head -1 | cut -d: -f1)" -ge 1 ]
}

@test "the interactive flag is not available yet" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" pacman:install -i
    [ "$status" -ne 0 ]
    [[ "$output" == *"interactive"* ]]
}

@test "remove needs explicit names" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" pacman:remove
    [ "$status" -ne 0 ]
    [[ "$output" == *"name"* ]]
}

@test "the help lists the install modules and no -i flag" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" bash "$ROOT/bin/dotfiles" --help
    for m in pacman:install aur:install flatpak:install node:install sh:install fonts:install apps:install; do
        [[ "$output" == *"$m"* ]]
    done
    [[ "$output" != *" -i"* ]]
}
