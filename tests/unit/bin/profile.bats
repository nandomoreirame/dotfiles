#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$HOME" "$DOTFILES/profiles/linux-arch" "$DOTFILES/bin" "$DOTFILES/bin/git"
    cp -r "$ROOT/lib" "$DOTFILES/lib"
    cp "$ROOT/bin/dotfiles" "$ROOT/bin/profile" "$DOTFILES/bin/"
    cp "$ROOT/bin/git/git-profile" "$DOTFILES/bin/git/"
    cp "$ROOT"/profiles/linux-arch/*.conf "$DOTFILES/profiles/linux-arch/" 2>/dev/null || true
    printf 'GIT_NAME="Jane Dev"\nGIT_EMAIL="jane@example.com"\n' > "$DOTFILES/profiles/linux-arch/git-personal.conf"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS"
    printf '#!/bin/sh\necho "gcloud $*" >> "%s"\n' "$LOG" > "$STUBS/gcloud"
    chmod +x "$STUBS/gcloud"
    CLI() {
        run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" TERM=xterm-256color \
            DOTFILES="$DOTFILES" DOTFILES_YES=1 bash "$DOTFILES/bin/dotfiles" "$@"
    }
}

@test "profile list shows the profiles found" {
    CLI profile list
    [ "$status" -eq 0 ]
    [[ "$output" == *"personal"* ]]
}

@test "switch writes the identity to gitconfig.local" {
    CLI profile switch personal
    [ "$status" -eq 0 ]
    grep -q "name = Jane Dev" "$HOME/.gitconfig.local"
}

@test "an unknown profile fails and lists the available ones" {
    CLI profile switch nope
    [ "$status" -ne 0 ]
    [[ "$output" == *"personal"* ]]
}

@test "show prints the active profile after a switch" {
    CLI profile switch personal
    CLI profile show
    [[ "$output" == *"personal"* ]]
}

@test "validate fails on a malformed profile file" {
    printf 'GIT_NAME=\n' > "$DOTFILES/profiles/linux-arch/git-broken.conf"
    CLI profile validate broken
    [ "$status" -ne 0 ]
}

@test "bin profile delegates to dotfiles profile" {
    run grep -n "dotfiles profile\|exec .*dotfiles" "$ROOT/bin/profile"
    [ "$status" -eq 0 ]
    run grep -n "dotfiles profile\|exec .*profile" "$ROOT/bin/git/git-profile"
    [ "$status" -eq 0 ]
}

@test "the wrappers print usage with --help" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" DOTFILES="$DOTFILES" bash "$DOTFILES/bin/profile" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"sage"* ]]
}

@test "status and doctor report the active profile" {
    CLI profile switch personal
    CLI --status
    [[ "$output" == *"personal"* ]]
}

@test "the profile command lists its subcommands in the help" {
    CLI --help
    for s in "profile list" "profile switch" "profile create" "hooks"; do
        [[ "$output" == *"${s%% *}"* ]]
    done
}
