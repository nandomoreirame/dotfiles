#!/usr/bin/env bats

# v5 config tracked under configs/noctalia (palettes, toml).
#
# Run:
#   ./tests/run-tests tests/unit/configs/noctalia-v5.bats

load '../../bats/helpers/setup'

NOCTALIA_DIR="$PROJECT_ROOT/configs/noctalia"

@test "palettes/ holds Terminal Noir with dark and light modes" {
    local palette="$NOCTALIA_DIR/palettes/Terminal Noir.json"
    [ -f "$palette" ]
    jq -e '.dark.mPrimary and .light.mPrimary' "$palette" >/dev/null
}

@test "v4 config files and plugin dir are gone" {
    [ ! -e "$NOCTALIA_DIR/settings.json" ]
    [ ! -e "$NOCTALIA_DIR/plugins.json" ]
    [ ! -e "$NOCTALIA_DIR/colors.json" ]
    [ ! -e "$NOCTALIA_DIR/colorschemes" ]
    [ ! -e "$NOCTALIA_DIR/model-usage-grok" ]
    [ ! -e "$NOCTALIA_DIR/plugins" ]
}

@test "niri autostarts noctalia directly and nothing launches qs" {
    local niri_cfg="$PROJECT_ROOT/configs/niri/config.kdl"

    grep -qx 'spawn-at-startup "noctalia"' "$niri_cfg"
    ! grep -q 'noctalia-session' "$niri_cfg"
    [ ! -e "$PROJECT_ROOT/bin/utils/noctalia-session" ]
    [ ! -e "$PROJECT_ROOT/bin/utils/noctalia-switch" ]
    ! grep -rqwE 'qs|noctalia-shell' "$PROJECT_ROOT/bin/utils" "$PROJECT_ROOT/bin/sys" "$niri_cfg"
}

@test "config.toml sets the dark custom theme, fonts, and validates" {
    if ! command -v noctalia >/dev/null 2>&1; then
        skip "noctalia binary not available"
    fi

    local config="$NOCTALIA_DIR/config.toml"
    [ -f "$config" ]
    grep -qx 'mode = "dark"' "$config"
    grep -qx 'source = "custom"' "$config"
    grep -qx 'custom_palette = "Terminal Noir"' "$config"
    grep -qx 'font_family = "Open Sans SemiBold"' "$config"
    grep -qx 'ui_scale = 0.95' "$config"

    run noctalia config validate "$NOCTALIA_DIR"
    assert_success
}

@test "config.toml hooks pause media on lock" {
    local config="$NOCTALIA_DIR/config.toml"
    [ -f "$config" ]
    grep -F 'session_locked' "$config" | grep -Fq '~/.dotfiles/bin/utils/nocta media-pause'
    run grep -F 'power_profile_changed' "$config"
    assert_failure
}

@test "config.toml idle matches: screen off 10 min, lock 11 min, suspend 30 min" {
    local config="$NOCTALIA_DIR/config.toml"
    [ -f "$config" ]
    grep -Fqx 'behavior_order = ["screen-off", "lock", "suspend"]' "$config"

    local name timeout action
    while read -r name timeout action; do
        run sed -n "/^\[idle\.behavior\.$name\]/,/^\[/p" "$config"
        assert_success
        [[ "$output" == *"timeout = $timeout"* ]]
        [[ "$output" == *"action = \"$action\""* ]]
        [[ "$output" == *"enabled = true"* ]]
    done <<'IDLE'
screen-off 600 screen_off
lock 660 lock
suspend 1800 lock_and_suspend
IDLE
}

@test "config.toml locks the session on suspend with no grace period" {
    local config="$NOCTALIA_DIR/config.toml"
    run sed -n '/^\[lockscreen\]/,/^\[/p' "$config"
    assert_success
    [[ "$output" == *"enabled = true"* ]]
    [[ "$output" == *"lock_before_suspend = true"* ]]
    [[ "$output" == *"grace_period_seconds = 0"* ]]
}

@test "config.toml keeps wallpaper rotation off" {
    local config="$NOCTALIA_DIR/config.toml"
    run sed -n '/^\[wallpaper\]/,/^\[wallpaper\.automation\]/p' "$config"
    assert_success
    [[ "$output" == *'fill_mode = "crop"'* ]]

    run sed -n '/^\[wallpaper\.automation\]/,/^\[/p' "$config"
    [[ "$output" == *"enabled = false"* ]]
}

@test "config.toml carries weather, night light, toasts and OSD" {
    if ! command -v noctalia >/dev/null 2>&1; then
        skip "noctalia binary not available"
    fi

    local config="$NOCTALIA_DIR/config.toml"
    grep -Fqx 'unit = "metric"' "$config"
    grep -Fqx 'temperature_night = 3611' "$config"
    ! grep -q 'avatar_path' "$config"
    run sed -n '/^\[notification\]/,/^\[/p' "$config"
    [[ "$output" == *'position = "top_right"'* ]]
    [[ "$output" == *'layer = "overlay"'* ]]
    [[ "$output" == *"follow_focused_output = true"* ]]
    run sed -n '/^\[osd\]/,/^\[/p' "$config"
    [[ "$output" == *'position = "top_right"'* ]]
    [[ "$output" == *"hide_delay_ms = 2000"* ]]

    run noctalia config validate "$NOCTALIA_DIR"
    assert_success
}

@test "bar.toml is a fully transparent full-width strip where only the islands show" {
    if ! command -v noctalia >/dev/null 2>&1; then
        skip "noctalia binary not available"
    fi

    local bar="$NOCTALIA_DIR/bar.toml"
    [ -f "$bar" ]
    grep -Fqx 'order = ["main"]' "$bar"
    run sed -n '/^\[bar\.main\]/,/^\[/p' "$bar"
    [[ "$output" == *'position = "top"'* ]]
    [[ "$output" == *"margin_edge = 0"* ]]
    [[ "$output" == *"margin_ends = 0"* ]]
    [[ "$output" == *"thickness = 34"* ]]
    [[ "$output" == *"background_opacity = 0.0"* ]]
    [[ "$output" == *"border_width = 0.0"* ]]
    [[ "$output" == *"shadow = false"* ]]
    [[ "$output" == *"concave_edge_corners = false"* ]]
    [[ "$output" == *"capsule = true"* ]]
    [[ "$output" == *'capsule_fill = "#202023"'* ]]
    [[ "$output" == *'capsule_border = "outline_variant"'* ]]
    run sed -n '/^\[\[bar\.main\.capsule_group\]\]/,/^$/p' "$bar"
    [ "$(grep -c 'fill = "#202023"' <<<"$output")" -eq 2 ]
    [ "$(grep -c 'border = "outline_variant"' <<<"$output")" -eq 2 ]

    run noctalia config validate "$NOCTALIA_DIR"
    assert_success
    [[ "$output" != *"unknown setting"* ]]
}

@test "bar.toml keeps the dock styled but turned off" {
    run sed -n '/^\[dock\]/,/^\[/p' "$NOCTALIA_DIR/bar.toml"
    [[ "$output" == *"enabled = false"* ]]
    [[ "$output" == *'position = "bottom"'* ]]
    [[ "$output" == *"margin_edge = 0"* ]]
    [[ "$output" == *"concave_edge_corners = true"* ]]
    [[ "$output" == *"radius = 20"* ]]
    [[ "$output" == *"background_opacity = 0.85"* ]]
    [[ "$output" == *'border = "outline_variant"'* ]]
    [[ "$output" == *"reserve_space = true"* ]]
}

@test "config.toml rounds the screen corners" {
    run sed -n '/^\[shell\.screen_corners\]/,/^\[/p' "$NOCTALIA_DIR/config.toml"
    [[ "$output" == *"enabled = true"* ]]
    [[ "$output" == *"size = 20"* ]]
}

@test "bar.toml built-in widgets carry the effective widget settings" {
    local bar="$NOCTALIA_DIR/bar.toml"
    local name expected
    while IFS='|' read -r name expected; do
        run sed -n "/^\[widget\.$name\]/,/^\[/p" "$bar"
        [[ "$output" == *"$expected"* ]] || { echo "widget.$name lacks: $expected"; return 1; }
    done <<'WID'
sysmon|stat = "ram_used"
media|max_length = 200
media|title_scroll = "always"
tray|drawer = true
keyboard_layout|color = "primary"
network|show_label = false
battery|display_mode = "glyph"
clock|format = "{:%A, %d %b %Y - %H:%M:%S}"
workspaces|show_labels = false
WID
    grep -Fq 'middle = "exec pwvucontrol || pavucontrol"' "$bar"
}

@test "plugins.toml uses official auto_update" {
    local plugins="$NOCTALIA_DIR/plugins.toml"
    [ -f "$plugins" ]
    grep -Fqx 'auto_update = "official"' "$plugins"
}

@test "config.toml opens bar panels near the click" {
    local config="$NOCTALIA_DIR/config.toml"
    run sed -n '/^\[shell\.panel\]/,/^\[/p' "$config"
    assert_success
    local panel
    for panel in control_center launcher clipboard wallpaper session; do
        [[ "$output" == *"open_near_click_$panel = true"* ]] || { echo "missing: $panel"; return 1; }
    done
}

@test "config.toml floats bar panels so they stay solid instead of inheriting bar opacity" {
    local config="$NOCTALIA_DIR/config.toml"
    run sed -n '/^\[shell\.panel\]/,/^\[/p' "$config"
    assert_success
    [[ "$output" == *'transparency_mode = "solid"'* ]]
    local panel
    for panel in control_center wallpaper session; do
        [[ "$output" == *"${panel}_placement = \"floating\""* ]] || { echo "not floating: $panel"; return 1; }
    done
}

@test "Terminal Noir palette tokens match the active theme" {
    local palette="$NOCTALIA_DIR/palettes/Terminal Noir.json"

    [ -f "$palette" ]

    [ "$(jq -r '.dark.mPrimary' "$palette")" = "#F5A623" ]
    [ "$(jq -r '.dark.mSecondary' "$palette")" = "#34D399" ]
    [ "$(jq -r '.dark.mSurface' "$palette")" = "#0B0B0C" ]
    [ "$(jq -r '.dark.mOnSurface' "$palette")" = "#F4F4F5" ]
    [ "$(jq -r '.light.mPrimary' "$palette")" = "#865700" ]
    [ "$(jq -r '.light.mSurface' "$palette")" = "#FBFAF7" ]

    sed -n '/^\[theme\]/,/^\[/p' "$NOCTALIA_DIR/config.toml" | grep -Fqx 'custom_palette = "Terminal Noir"'
}

@test "config.toml themes GTK and btop from the active palette via built-in templates" {
    run sed -n '/^\[theme\.templates\]/,/^\[/p' "$NOCTALIA_DIR/config.toml"
    [[ "$output" == *"enable_builtin_templates = true"* ]]
    [[ "$output" == *'builtin_ids = ["gtk3", "gtk4", "btop"]'* ]]
}
