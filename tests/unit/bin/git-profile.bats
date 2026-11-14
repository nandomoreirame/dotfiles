#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
}

@test "git-profile delegates to profile" {
    run grep -nE "dotfiles profile|exec .*profile" "$ROOT/bin/git/git-profile"
    [ "$status" -eq 0 ]
    run grep -n "source .*profiles.sh" "$ROOT/bin/git/git-profile"
    [ "$status" -ne 0 ]
}

@test "git-profile --help prints usage" {
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" bash "$ROOT/bin/git/git-profile" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"sage"* ]]
}
