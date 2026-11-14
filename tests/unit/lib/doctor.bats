#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES="$BATS_TEST_TMPDIR/dot"
    export DOTFILES_PRIVATE="$DOTFILES/private"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    mkdir -p "$HOME" "$DOTFILES/configs" "$DOTFILES/private" "$DOTFILES/packages" "$STUBS"
    printf '[paths]\n' > "$DOTFILES/configs/links.conf"
    # Keep real git on PATH so identity checks can read ~/.gitconfig.local.
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/curl"
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/zsh"
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/yay"
    printf '#!/bin/sh\n[ "$1" = "-Q" ] && exit 0\nexit 0\n' > "$STUBS/pacman"
    chmod +x "$STUBS"/*
    printf '[user]\n\tname = Jane Dev\n\temail = jane@example.com\n' > "$HOME/.gitconfig.local"
}

run_doc() {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" DOTFILES_DOCTOR_SKIP_PACKAGES="${DOTFILES_DOCTOR_SKIP_PACKAGES:-1}" TERM=xterm-256color "$@" bash -c "source '$ROOT/lib/doctor.sh'; _doctor"
}

@test "doctor passes a healthy temporary home" {
    run_doc
    [ "$status" -eq 0 ]
}

@test "doctor reports a broken link" {
    mkdir -p "$DOTFILES/configs/x"
    echo a > "$DOTFILES/configs/x/c"
    printf '[paths]\nconfigs/x/c | .config/x/c |\n' > "$DOTFILES/configs/links.conf"
    ln -s /srv/example/missing "$HOME/.config/x/c" 2>/dev/null || {
        mkdir -p "$HOME/.config/x"
        ln -sf /srv/example/missing "$HOME/.config/x/c"
    }
    run_doc
    [ "$status" -ne 0 ]
    [[ "$output" == *"broken"* ]]
}

@test "doctor reports unset identity" {
    rm -f "$HOME/.gitconfig.local"
    run_doc
    [ "$status" -ne 0 ]
    [[ "$output" == *"identity"* ]]
}

@test "doctor reports missing prerequisites" {
    run env -i HOME="$HOME" PATH="$STUBS" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" DOTFILES_DOCTOR_SKIP_PACKAGES=1 TERM=dumb /usr/bin/bash -c "
        source '$ROOT/lib/doctor.sh'
        _doctor
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"prerequisites"* ]]
    [[ "$output" == *"missing git"* ]]
}

@test "doctor names a missing package without the skip variable" {
    printf '## core\nmissing-pkg\n' > "$DOTFILES/packages/pacman.list"
    printf '#!/bin/sh\n[ "$1" = "-Q" ] && exit 1\nexit 0\n' > "$STUBS/pacman"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" TERM=xterm-256color bash -c "source '$ROOT/lib/doctor.sh'; _doctor"
    [ "$status" -ne 0 ]
    [[ "$output" == *"missing-pkg"* ]]
}
