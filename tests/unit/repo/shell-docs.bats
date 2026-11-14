#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; R="$ROOT/README.md"; }

@test "readme documents the shell configs" {
    for k in ".zshenv" ".zshrc" "private/shell" "powerlevel10k" "zsh-autosuggestions" ".gitconfig.local"; do grep -q -- "$k" "$R"; done
}

@test "readme says the unsafe wrappers are absent" {
    grep -qi "permission" "$R"
    grep -q "claude" "$R"
    grep -qi "overlay" "$R"
}

@test "the overlay document lists the shell hooks" {
    grep -q "private/shell" "$ROOT/private/private-overlay.md"
    grep -q "10-personal" "$ROOT/private/private-overlay.md"
}

@test "changelog records the shell milestone" {
    grep -qi "zsh" "$ROOT/CHANGELOG.md"
}

@test "the whole suite gate is green" {
    run bash "$ROOT/scripts/public-check" "$ROOT"
    [ "$status" -eq 0 ]
}
