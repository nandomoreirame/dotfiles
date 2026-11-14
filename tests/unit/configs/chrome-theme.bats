#!/usr/bin/env bats

# Google Chrome theme extension with the Terminal Noir palette
# . Chrome themes have no light variant, so it mirrors the
# dark side of configs/noctalia/palettes/Terminal Noir.json.
#
# Run:
#   ./tests/run-tests unit/configs/chrome-theme.bats

load '../../bats/helpers/setup'

MANIFEST="$PROJECT_ROOT/configs/chrome/terminal-noir-theme/manifest.json"
PALETTE="$PROJECT_ROOT/configs/noctalia/palettes/Terminal Noir.json"

# "#RRGGBB" from the palette dark side -> "[r,g,b]" as Chrome expects.
palette_rgb() {
    jq -c --arg k "$1" '
        .dark[$k] | ltrimstr("#") | ascii_downcase
        | [.[0:2], .[2:4], .[4:6]]
        | map(explode | map(if . >= 97 then . - 87 else . - 48 end) | .[0] * 16 + .[1])' "$PALETTE"
}

theme_color() {
    jq -c --arg k "$1" '.theme.colors[$k]' "$MANIFEST"
}

@test "manifest is a valid MV3 theme" {
    [ -f "$MANIFEST" ]
    jq -e '.manifest_version == 3 and .name == "Terminal Noir" and (.theme.colors | type == "object")' "$MANIFEST"
}

@test "frame and omnibox use the palette surface" {
    [ "$(theme_color frame)" = "$(palette_rgb mSurface)" ]
    [ "$(theme_color frame_inactive)" = "$(palette_rgb mSurface)" ]
    [ "$(theme_color omnibox_background)" = "$(palette_rgb mSurface)" ]
    [ "$(theme_color ntp_background)" = "$(palette_rgb mSurface)" ]
}

@test "toolbar and active tab use the palette surface variant" {
    [ "$(theme_color toolbar)" = "$(palette_rgb mSurfaceVariant)" ]
}

@test "text uses the palette foreground and muted foreground" {
    [ "$(theme_color tab_text)" = "$(palette_rgb mOnSurface)" ]
    [ "$(theme_color bookmark_text)" = "$(palette_rgb mOnSurface)" ]
    [ "$(theme_color omnibox_text)" = "$(palette_rgb mOnSurface)" ]
    [ "$(theme_color ntp_text)" = "$(palette_rgb mOnSurface)" ]
    [ "$(theme_color tab_background_text)" = "$(palette_rgb mOnSurfaceVariant)" ]
    [ "$(theme_color tab_background_text_inactive)" = "$(palette_rgb mOnSurfaceVariant)" ]
}

@test "toolbar icons and new tab links use the primary amber" {
    [ "$(theme_color toolbar_button_icon)" = "$(palette_rgb mPrimary)" ]
    [ "$(theme_color ntp_link)" = "$(palette_rgb mPrimary)" ]
}

@test "chrome theme manifest parses" {
    run jq -e '.name and .version' "$MANIFEST"
    [ "$status" -eq 0 ]
}

@test "browser flags do not disable web security" {
    run grep -rnE 'disable-web-security|disable-site-isolation|--no-sandbox|ignore-certificate' \
        "$PROJECT_ROOT/configs/chrome-flags.conf" \
        "$PROJECT_ROOT/configs/electron-flags.conf" \
        "$PROJECT_ROOT/configs/electron40-flags.conf" \
        "$PROJECT_ROOT/configs/applications"
    [ "$status" -ne 0 ]
}

@test "desktop and gtk configs hold no personal data" {
    run grep -rnE "@gmail|/home/[a-z]|input-remapper" \
        "$PROJECT_ROOT/configs/gtk-3.0" \
        "$PROJECT_ROOT/configs/gtk-4.0" \
        "$PROJECT_ROOT/configs/applications" \
        "$PROJECT_ROOT/configs/fcitx5" \
        "$PROJECT_ROOT/configs/chrome-flags.conf"
    [ "$status" -ne 0 ]
}
