#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; R="$ROOT/README.md"; }

@test "readme documents the apps and the theme" {
    for k in ghostty tmux neovim "VS Code" gtk obsidian espanso "Terminal Noir" "build-terminal-noir"; do grep -qi -- "$k" "$R"; done
}

@test "readme names the files kept private" {
    for k in opencode solaar "input-remapper" "base.yml"; do grep -qi -- "$k" "$R" "$ROOT/private/private-overlay.md"; done
}

@test "readme explains each app carries its own theme files" {
    grep -qi "next to" "$R" || grep -qi "inside each" "$R"
}

@test "third party notes cover the bundled themes" {
    grep -qi "catppuccin" "$ROOT/THIRD-PARTY.md"
}

@test "changelog records the apps milestone" {
    grep -qi "terminal noir" "$ROOT/CHANGELOG.md"
}
