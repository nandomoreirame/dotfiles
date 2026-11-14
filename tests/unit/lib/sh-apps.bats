#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT" TMP_DIR="$BATS_TEST_TMPDIR/tmp"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME" "$TMP_DIR"
    printf '#!/bin/sh\necho "curl $*" >> "%s"\nout=""\nwhile [ $# -gt 0 ]; do [ "$1" = "-o" ] && out="$2"; shift; done\n[ -n "$out" ] && printf "installer-body" > "$out" || printf "installer-body"\n' "$LOG" > "$STUBS/curl"
    printf '#!/bin/sh\necho "sh $*" >> "%s"\n' "$LOG" > "$STUBS/sh"
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\nexit 1\n' "$LOG" > "$STUBS/pacman"
    printf '#!/bin/sh\necho "sudo $*" >> "%s"\nexec "$@"\n' "$LOG" > "$STUBS/sudo"
    chmod +x "$STUBS"/*
    SUM="$(printf 'installer-body' | sha256sum | cut -d' ' -f1)"
    TABLE="$BATS_TEST_TMPDIR/remote.conf"
    export DOTFILES_REMOTE_TABLE="$TABLE"
    : > "$LOG"
}

run_sh() {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" TMP_DIR="$TMP_DIR" DOTFILES_REMOTE_TABLE="$TABLE" TERM=xterm-256color "$@" bash -c "source '$ROOT/lib/sh-apps.sh'; $PCMD"
}

@test "the default sh group is ohmyzsh mise docker" {
    PCMD='_get_default_sh_apps'
    run_sh
    [ "$output" = "ohmyzsh mise docker" ]
}

@test "a checksum mismatch aborts the install" {
    printf 'ohmyzsh|https://example.com/install.sh|%s\n' "0000000000000000000000000000000000000000000000000000000000000000" > "$TABLE"
    PCMD='_install_ohmyzsh'
    run_sh
    [ "$status" -ne 0 ]
    ! grep -q "^sh " "$LOG"
    [[ "$output" != *"continuing anyway"* ]]
}

@test "a matching checksum runs the installer" {
    printf 'ohmyzsh|https://example.com/install.sh|%s\n' "$SUM" > "$TABLE"
    PCMD='_install_ohmyzsh'
    run_sh
    [ "$status" -eq 0 ]
    grep -q "^sh " "$LOG"
}

@test "no remote means no download" {
    printf 'ohmyzsh|https://example.com/install.sh|%s\n' "$SUM" > "$TABLE"
    PCMD='_install_ohmyzsh'
    run_sh DOTFILES_NO_REMOTE=1
    ! grep -q "^curl" "$LOG"
    [[ "$output" == *"--no-remote"* ]] || [[ "$output" == *"skipp"* ]]
}

@test "mise installs through pacman" {
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\nexit 0\n' "$LOG" > "$STUBS/pacman"
    PCMD='_install_mise'
    run_sh DOTFILES_YES=1
    grep -q "pacman .*mise" "$LOG"
    ! grep -q "mise.run" "$LOG"
}

@test "the code has no pipe to a shell and no unverified fetch" {
    run grep -nE "curl[^|]*\|\s*(ba)?sh|mise\.run|continuing anyway|raw\.githubusercontent\.com/ohmyzsh/ohmyzsh/master" "$ROOT/lib/sh-apps.sh"
    [ "$status" -ne 0 ]
}

@test "the remote table pins a commit and a sha256" {
    grep -E '^ohmyzsh\|https://raw\.githubusercontent\.com/ohmyzsh/ohmyzsh/[0-9a-f]{40}/tools/install\.sh\|[0-9a-f]{64}$' "$ROOT/scripts/remote-installers.conf"
}

@test "awscli terraform and the AI cli are not offered" {
    PCMD='_get_app_function awscli; _get_app_function terraform; _get_app_function agy-cli'
    run_sh
    [ -z "$output" ]
}
