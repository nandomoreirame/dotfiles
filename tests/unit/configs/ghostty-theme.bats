#!/usr/bin/env bats

# Ghostty uses the Terminal Noir palette, dark and light.
# The theme files must match the `terminal` block of the Noctalia palette,
# which is the single source of these colors.
#
# Run:
#   ./tests/run-tests unit/configs/ghostty-theme.bats

load '../../bats/helpers/setup'

GHOSTTY_DIR="$PROJECT_ROOT/configs/ghostty"
PALETTE="$PROJECT_ROOT/configs/noctalia/palettes/Terminal Noir.json"

# Render the expected Ghostty theme for one mode from the palette JSON.
expected_theme() {
    jq -r --arg m "$1" '
        .[$m].terminal as $t
        | ["black","red","green","yellow","blue","magenta","cyan","white"] as $names
        | ([range(0; 8) as $i | "palette = \($i)=\($t.normal[$names[$i]])"]
           + [range(0; 8) as $i | "palette = \($i + 8)=\($t.bright[$names[$i]])"]
           + ["background = \($t.background)",
              "foreground = \($t.foreground)",
              "cursor-color = \($t.cursor)",
              "cursor-text = \($t.cursorText)",
              "selection-background = \($t.selectionBg)",
              "selection-foreground = \($t.selectionFg)"])
        | .[] | ascii_downcase' "$PALETTE"
}

# Theme file without comments or blank lines, lowercased.
theme_body() {
    grep -vE '^[[:space:]]*(#|$)' "$GHOSTTY_DIR/themes/$1" | tr '[:upper:]' '[:lower:]'
}

@test "dark theme matches the palette terminal colors" {
    [ -f "$GHOSTTY_DIR/themes/terminal-noir-dark" ]
    [ "$(theme_body terminal-noir-dark)" = "$(expected_theme dark)" ]
}

@test "light theme matches the palette terminal colors" {
    [ -f "$GHOSTTY_DIR/themes/terminal-noir-light" ]
    [ "$(theme_body terminal-noir-light)" = "$(expected_theme light)" ]
}

@test "config follows the system light/dark preference with both themes" {
    grep -Fqx 'theme = light:terminal-noir-light,dark:terminal-noir-dark' "$GHOSTTY_DIR/config"
}
