#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; R="$ROOT/README.md"; }

@test "readme documents the desktop hooks" {
    for k in niri noctalia "private.kdl" "monitor.kdl" "bar.toml" "plugins.toml" NOCTALIA_PLUGIN_AUTHOR GAME_MODE_APPS; do grep -qi -- "$k" "$R"; done
}

@test "readme says how a private entry replaces a desktop file" {
    grep -qi "links.conf" "$R"
    grep -qi "replace" "$R"
}

@test "the overlay doc lists the files the author keeps private" {
    for k in private.kdl monitor.kdl bar.toml plugins.toml niri-hdmi-automode audio-jack-autoswitch; do grep -qi -- "$k" "$ROOT/private/private-overlay.md"; done
}

@test "changelog records the desktop milestone" {
    grep -qi "niri" "$ROOT/CHANGELOG.md"
}
