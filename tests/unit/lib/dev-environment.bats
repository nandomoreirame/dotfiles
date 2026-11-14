#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    mkdir -p "$HOME"
}

@test "dev environment creates missing directories only" {
    export DOTFILES_DEV_DIRS="$HOME/dev/projects $HOME/dev/extra"
    mkdir -p "$HOME/dev/projects/existing"
    printf 'keep\n' > "$HOME/dev/projects/existing/file.txt"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_DEV_DIRS="$DOTFILES_DEV_DIRS" TERM=xterm-256color bash -c "source '$ROOT/lib/dev-environment.sh'; _setup_dev_environment"
    [ "$status" -eq 0 ]
    [ -d "$HOME/dev/projects" ]
    [ -d "$HOME/dev/extra" ]
    [ -f "$HOME/dev/projects/existing/file.txt" ]
    [ "$(cat "$HOME/dev/projects/existing/file.txt")" = "keep" ]
}

@test "dev environment defaults to HOME/dev/projects" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" TERM=xterm-256color bash -c "source '$ROOT/lib/dev-environment.sh'; _setup_dev_environment"
    [ "$status" -eq 0 ]
    [ -d "$HOME/dev/projects" ]
}

@test "dev environment fails when HOME is not writable" {
    # Use a non-writable parent by pointing HOME at a file path under a locked dir.
    locked="$BATS_TEST_TMPDIR/locked"
    mkdir -p "$locked"
    chmod 000 "$locked"
    run env -i HOME="$locked/home" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" TERM=dumb bash -c "source '$ROOT/lib/dev-environment.sh'; _setup_dev_environment"
    chmod 755 "$locked"
    [ "$status" -ne 0 ]
    [[ "$output" == *"writable"* ]] || [[ "$output" == *"write"* ]] || [[ "$output" == *"HOME"* ]]
}
