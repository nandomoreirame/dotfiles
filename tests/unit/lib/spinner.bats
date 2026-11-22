#!/usr/bin/env bats

# lib/spinner.sh: spin_run shows a braille spinner while a command runs. It is
# shared by the installers (bash) and the zsh push/pull/commit wrappers.

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
}

# Bash: source the lib and run $1. Extra env (DOTFILES_SPINNER, SPIN_*) via $2.
brun() { run --separate-stderr env -i HOME="$BATS_TEST_TMPDIR" PATH="/usr/bin:/bin" $2 bash -c "source '$ROOT/lib/spinner.sh'; $1"; }

@test "spin_run keeps the command exit code" {
    brun 'spin_run "x" sh -c "exit 5"'
    [ "$status" -eq 5 ]
    brun 'spin_run "x" true'
    [ "$status" -eq 0 ]
}

@test "spin_run without a terminal prints the message and the command output" {
    brun 'spin_run "Installing demo" echo hello'
    [ "$status" -eq 0 ]
    [[ "$output$stderr" == *"Installing demo"* ]]
    [[ "$output" == *"hello"* ]]
}

@test "spin_run idle timeout kills a silent command and returns 124" {
    brun 'spin_run "x" sleep 30' "SPIN_IDLE=1"
    [ "$status" -eq 124 ]
}

@test "spin_run copies the output to SPIN_LOG" {
    log="$BATS_TEST_TMPDIR/out.log"
    brun 'spin_run "x" echo logged' "SPIN_LOG=$log"
    grep -qx logged "$log"
}

@test "with a terminal, success hides the output and prints a check line" {
    brun 'spin_run "Installing demo" echo hidden-output' "DOTFILES_SPINNER=1"
    [ "$status" -eq 0 ]
    [[ "$output" != *"hidden-output"* ]]
    [[ "$stderr" == *"Installing demo"* ]]
}

@test "with a terminal, SPIN_SHOW_OUTPUT=1 prints the output after success" {
    brun 'spin_run "x" echo shown-output' "DOTFILES_SPINNER=1 SPIN_SHOW_OUTPUT=1"
    [[ "$output" == *"shown-output"* ]]
}

@test "with a terminal, failure prints the command output" {
    brun 'spin_run "Installing demo" sh -c "echo boom >&2; exit 3"' "DOTFILES_SPINNER=1"
    [ "$status" -eq 3 ]
    [[ "$output$stderr" == *"boom"* ]]
}

@test "DOTFILES_SPINNER=0 never draws spinner frames" {
    brun 'spin_run "x" echo plain' "DOTFILES_SPINNER=0"
    [[ "$stderr" != *$'\r'* ]]
}

@test "spin_run works when zsh sources the lib" {
    command -v zsh >/dev/null || skip "zsh not installed"
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="/usr/bin:/bin" DOTFILES="$ROOT" zsh -f -c "source '$ROOT/lib/spinner.sh'; spin_run x sh -c 'echo z; exit 4'"
    [ "$status" -eq 4 ]
    [[ "$output" == *"z"* ]]
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="/usr/bin:/bin" DOTFILES="$ROOT" SPIN_IDLE=1 zsh -f -c "source '$ROOT/lib/spinner.sh'; spin_run x sleep 30"
    [ "$status" -eq 124 ]
}

@test "spin_sudo_prime skips sudo without a terminal" {
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    printf '#!/bin/sh\necho called >> "%s/sudo.log"\n' "$BATS_TEST_TMPDIR" > "$BATS_TEST_TMPDIR/bin/sudo"
    chmod +x "$BATS_TEST_TMPDIR/bin/sudo"
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin" bash -c "source '$ROOT/lib/spinner.sh'; spin_sudo_prime"
    [ "$status" -eq 0 ]
    [ ! -e "$BATS_TEST_TMPDIR/sudo.log" ]
}
