#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME" "$BATS_TEST_TMPDIR/dot/configs/mise"
    export DOTFILES="$BATS_TEST_TMPDIR/dot"
    printf '#!/bin/sh\necho "mise $*" >> "%s"\nexit 0\n' "$LOG" > "$STUBS/mise"
    chmod +x "$STUBS/mise"
    : > "$LOG"
}

run_mise() {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" TERM=xterm-256color "$@" bash -c "source '$ROOT/lib/mise-packages.sh'; $PCMD"
}

@test "mise packages fail when config is missing" {
    PCMD='_install_mise_packages'
    run_mise
    [ "$status" -ne 0 ]
    [[ "$output" == *"mise config not found"* ]]
}

@test "mise packages call mise install when config exists" {
    printf '[tools]\nnode = "lts"\n' > "$DOTFILES/configs/mise/config.toml"
    PCMD='_install_mise_packages'
    run_mise
    [ "$status" -eq 0 ]
    grep -q "mise install" "$LOG"
}

@test "mise packages refuse when mise is absent" {
    printf '[tools]\nnode = "lts"\n' > "$DOTFILES/configs/mise/config.toml"
    rm -f "$STUBS/mise"
    PCMD='_install_mise_packages'
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" TERM=dumb bash -c "source '$ROOT/lib/mise-packages.sh'; $PCMD"
    # If the host has mise, skip isolation check.
    if command -v mise >/dev/null 2>&1; then
        skip "host has mise on PATH"
    fi
    [ "$status" -ne 0 ]
    [[ "$output" == *"mise not found"* ]]
}

@test "mise packages dry-run prints and runs nothing" {
    printf '[tools]\nnode = "lts"\n' > "$DOTFILES/configs/mise/config.toml"
    PCMD='_install_mise_packages'
    run_mise DOTFILES_DRY_RUN=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    ! grep -q "^mise install" "$LOG"
}
