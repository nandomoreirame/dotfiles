#!/usr/bin/env bats

# Vicinae (launcher) uses the Terminal Noir palette.
# Every color in the theme must come from the palette sources, and the
# versioned config must select the theme.
#
# Run:
#   ./tests/run-tests unit/configs/vicinae-theme.bats

load '../../bats/helpers/setup'

VICINAE_DIR="$PROJECT_ROOT/configs/vicinae"
THEME="$VICINAE_DIR/themes/terminal-noir.toml"
PALETTE="$PROJECT_ROOT/configs/noctalia/palettes/Terminal Noir.json"
SYNTAX="$PROJECT_ROOT/configs/themes/terminal-noir/syntax.json"
LINKS="$PROJECT_ROOT/configs/links.conf"

# All hex colors (6 digits, alpha dropped) defined by the palette sources.
source_hexes() {
    cat "$PALETTE" "$SYNTAX" | grep -oiE '#[0-9a-f]{6}' | tr '[:upper:]' '[:lower:]' | sort -u
}

@test "theme file exists and declares a dark Terminal Noir theme" {
    [ -f "$THEME" ]
    grep -Fqx 'name = "Terminal Noir"' "$THEME"
    grep -Fqx 'variant = "dark"' "$THEME"
}

@test "every theme color comes from the Terminal Noir palette sources" {
    local allowed bad=""
    allowed="$(source_hexes)"
    while read -r hex; do
        grep -Fqx "${hex:0:7}" <<<"$allowed" || bad+="$hex "
    done < <(grep -oiE '#[0-9a-f]{6,8}' "$THEME" | tr '[:upper:]' '[:lower:]' | sort -u)
    [ -z "$bad" ] || { echo "colors outside the palette: $bad"; false; }
}

@test "core colors match the palette surface, text and primary" {
    grep -Fqx 'background = "#0B0B0C"' "$THEME"
    grep -Fqx 'foreground = "#F4F4F5"' "$THEME"
    grep -Fqx 'accent = "#F5A623"' "$THEME"
}

@test "versioned config selects the theme for the dark mode" {
    [ "$(jq -r '.theme.dark.name' "$VICINAE_DIR/dotfiles.json")" = "terminal-noir" ]
}

@test "links.conf links the theme and the versioned config" {
    grep -Fqx 'configs/vicinae/themes/terminal-noir.toml | .local/share/vicinae/themes/terminal-noir.toml |' "$LINKS"
    grep -Fqx 'configs/vicinae/dotfiles.json | .config/vicinae/dotfiles.json |' "$LINKS"
}

@test "the versioned config only imports into the GUI-owned settings.json" {
    [ ! -e "$VICINAE_DIR/settings.json" ]
    run jq -e '.theme and .launcher_window' "$VICINAE_DIR/dotfiles.json"
    [ "$status" -eq 0 ]
}
