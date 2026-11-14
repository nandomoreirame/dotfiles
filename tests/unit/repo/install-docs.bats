#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; R="$ROOT/README.md"; }

@test "readme documents the new machine flow" {
    for k in "install.sh --dry-run" "install.sh" "dotfiles init" "dotfiles doctor" "--no-remote" "--group"; do
        grep -q -- "$k" "$R"
    done
}

@test "readme documents the package groups and the private list" {
    for g in core shell containers fonts desktop; do
        grep -q "$g" "$R"
    done
    grep -q "private/packages" "$R"
}

@test "readme documents every network fetch" {
    grep -q "^## Security" "$R"
    grep -qi "oh-my-zsh" "$R"
    grep -qi "sha-256\|sha256" "$R"
    grep -qi "pacman\|AUR\|flatpak\|npm" "$R"
    grep -qi "sudo" "$R"
}

@test "readme states what is not installed" {
    grep -qi "does not download fonts\|no font downloads\|fonts come from" "$R"
}

@test "readme no longer says the project is not usable" {
    run grep -qi "not usable yet" "$R"
    [ "$status" -ne 0 ]
}

@test "the changelog records the install flow" {
    grep -qi "install" "$ROOT/CHANGELOG.md"
}
