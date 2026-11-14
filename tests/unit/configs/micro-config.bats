#!/usr/bin/env bats

# Micro editor config lives in configs/micro and is linked into ~/.config/micro.
# Ctrl+Q is taken by niri (close-window), so Micro quits with Ctrl+W instead.
#
# Run:
#   ./tests/run-tests unit/configs/micro-config.bats

load '../../bats/helpers/setup'

MICRO_DIR="$PROJECT_ROOT/configs/micro"

@test "settings.json is valid JSON and selects the terminal-noir scheme" {
    jq -e '.colorscheme == "terminal-noir"' "$MICRO_DIR/settings.json"
}

@test "the selected colorscheme ships in configs/micro/colorschemes" {
    [ -f "$MICRO_DIR/colorschemes/terminal-noir.micro" ]
}

@test "bindings.json quits on Ctrl+W because niri owns Ctrl+Q" {
    jq -e '.["Ctrl-w"] == "Quit"' "$MICRO_DIR/bindings.json"
}
