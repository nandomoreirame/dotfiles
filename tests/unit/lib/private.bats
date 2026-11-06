#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export DOTFILES="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$DOTFILES"
}

@test "private helpers are silent without private" {
    run bash -c "source '$ROOT/lib/private.sh'; _private_has bin; echo rc=\$?; _private_path bin"
    [ "$status" -eq 0 ]
    [[ "$output" == *"rc=1"* ]]
    [[ "$output" == *"$DOTFILES/private/bin"* ]]
    [[ "$output" != *"rror"* ]]
}

@test "private helpers see an existing directory" {
    mkdir -p "$DOTFILES/private/bin"
    run bash -c "source '$ROOT/lib/private.sh'; _private_has bin"
    [ "$status" -eq 0 ]
}

@test "DOTFILES_PRIVATE can be overridden" {
    run bash -c "export DOTFILES_PRIVATE=/tmp/x; source '$ROOT/lib/private.sh'; echo \$DOTFILES_PRIVATE"
    [ "$output" = "/tmp/x" ]
}

@test "sourcing twice is harmless" {
    run bash -c "source '$ROOT/lib/private.sh'; source '$ROOT/lib/private.sh'; echo ok"
    [ "$output" = "ok" ]
}

@test "the overlay docs describe every directory and the variable" {
    for f in "$ROOT/docs/private-overlay.md" "$ROOT/private.example/README.md"; do
        for k in bin shell links.conf packages setup espanso profiles docs; do
            grep -q "$k" "$f"
        done
    done
    grep -q "DOTFILES_PRIVATE" "$ROOT/docs/private-overlay.md"
}
