#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
    CLI() { run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color bash "$ROOT/bin/dotfiles" "$@"; }
}

@test "help prints usage and exits 0" {
    CLI --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"links"* ]]
    [[ "$output" == *"--verify"* ]]
}

@test "version prints a version" {
    CLI --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

@test "an unknown command is rejected with the help text" {
    CLI frobnicate
    [ "$status" -ne 0 ]
    [[ "$output" == *"frobnicate"* ]]
    [[ "$output" == *"links"* ]]
}

@test "help lists only implemented commands" {
    CLI --help
    for c in pacman:install aur:install flatpak:install node:install sh:install fonts:install setup langs:install apps:install profile; do
        [[ "$output" != *"$c"* ]]
    done
}

@test "help is English" {
    CLI --help
    [[ "$output" != *"Exibe"* ]]
    [[ "$output" != *"Cria"* ]]
}

@test "links without an argument shows its help and fails" {
    CLI links
    [ "$status" -ne 0 ]
}

@test "verify works through the command line" {
    mkdir -p "$BATS_TEST_TMPDIR/dot/configs"; printf '[paths]\n' > "$BATS_TEST_TMPDIR/dot/configs/links.conf"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$BATS_TEST_TMPDIR/dot" bash "$ROOT/bin/dotfiles" --verify
    [ "$status" -eq 0 ]
}

@test "a symlink on PATH resolves the clone" {
    ln -s "$ROOT/bin/dotfiles" "$HOME/df"
    run env -i HOME="$HOME" PATH=/usr/bin:/bin bash "$HOME/df" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"$ROOT"* ]]
}

@test "extra arguments are rejected" {
    CLI --help unexpected
    [ "$status" -ne 0 ]
    CLI links --all unexpected
    [ "$status" -ne 0 ]
}
