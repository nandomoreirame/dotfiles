#!/usr/bin/env bats

# tmux config in configs/tmux is linked to ~/.config/tmux/tmux.conf. It carries the Terminal Noir
# theme (status bar tabs, pane borders, popups) and the Ctrl+b prefix.
#
# Run:
#   ./tests/run-tests unit/configs/tmux-config.bats

load '../../bats/helpers/setup'

CONF="$PROJECT_ROOT/configs/tmux/tmux.conf"
SOURCES=("$PROJECT_ROOT/configs/themes/terminal-noir/syntax.json" "$PROJECT_ROOT/configs/noctalia/palettes/Terminal Noir.json")

setup() {
    SOCK="noir-test-$$"
}

teardown() {
    command -v tmux >/dev/null && tmux -L "$SOCK" kill-server 2>/dev/null || true
}

tmux_test() {
    env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color LC_ALL=C.UTF-8 tmux -L "$SOCK" "$@"
}

start_server() {
    command -v tmux >/dev/null || skip "tmux is not installed"
    tmux_test -f "$CONF" new-session -d -s teste -x 120 -y 30
}

@test "every color in the config is a Terminal Noir color from the dotfiles theme sources" {
    colors="$(grep -ioE '#[0-9a-f]{6}' "$CONF" | tr 'a-f' 'A-F' | sort -u)"
    [ -n "$colors" ]
    for c in $colors; do
        cat "${SOURCES[@]}" | grep -qi "$c" || { echo "not in the theme sources: $c"; return 1; }
    done
}

@test "the theme uses the palette instead of terminal color names" {
    run grep -nE '(fg|bg)=(blue|black|white|red|green|yellow|brightblack|default)' "$CONF"
    [ "$status" -eq 1 ]
    for c in 0B0B0C 121214 18181B F4F4F5 6B6B74 F5A623; do
        grep -qi "#$c" "$CONF"
    done
}

@test "the prefix is Ctrl+b and Ctrl+Space is not bound" {
    grep -qE '^set -g prefix C-b$' "$CONF"
    run grep -nE 'C-Space|prefix2' "$CONF"
    [ "$status" -eq 1 ]
}

@test "the config loads without errors and sets the prefix" {
    start_server
    [ "$(tmux_test show -gv prefix)" = "C-b" ]
    run tmux_test source-file "$CONF"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "tmux: pane borders are subtle and the active pane is amber" {
    start_server
    [[ "$(tmux_test show -gv pane-border-style)" == *"#222226"* || "$(tmux_test show -gv pane-border-style)" == *"#6B6B74"* ]]
    [[ "$(tmux_test show -gv pane-active-border-style)" == *"#F5A623"* ]]
    [ -n "$(tmux_test show -gv pane-border-lines)" ]
}

@test "tmux: the status bar sits on the raised surface and the tabs show index and name" {
    start_server
    [[ "$(tmux_test show -gv status-style)" == *"bg=#121214"* ]]
    current="$(tmux_test show -gv window-status-current-format)"
    other="$(tmux_test show -gv window-status-format)"
    [[ "$current" == *"#I"* && "$current" == *"#W"* && "$current" == *"#F"* || "$current" == *"window_zoomed_flag"* ]]
    [[ "$other" == *"#I"* && "$other" == *"#W"* ]]
    [[ "$current" == *"#F5A623"* ]]
}

@test "tmux: the session pill is on the right and changes color while the prefix is pressed" {
    start_server
    right="$(tmux_test show -gv status-right)"
    [[ "$right" == *"#S"* && "$right" == *"client_prefix"* ]]
    out="$(tmux_test display-message -p -t teste '#{T:status-right}')"
    [[ "$out" == *"teste"* ]]
    left="$(tmux_test show -gv status-left)"
    [[ "$left" != *"#S"* ]]
}

@test "tmux: tabs are named after the folder in a shell and after the command otherwise" {
    start_server
    fmt="$(tmux_test show -gv automatic-rename-format)"
    [[ "$fmt" == *"pane_current_path"* && "$fmt" == *"pane_current_command"* ]]
}

@test "tmux: popups, menus, messages and copy mode use the theme" {
    start_server
    for opt in popup-style popup-border-style menu-style menu-border-style menu-selected-style message-style mode-style; do
        value="$(tmux_test show -gv "$opt")"
        [[ "$value" == *"#"* ]] || { echo "$opt has no palette color: $value"; return 1; }
    done
}

@test "the user's pane, window and session bindings are still there" {
    start_server
    keys="$(tmux_test list-keys)"
    for needle in "split-window -h" "split-window -v" "select-window -t 1" "switch-client -p"; do
        [[ "$keys" == *"$needle"* ]] || { echo "missing binding: $needle"; return 1; }
    done
}

@test "tmux: the tabs sit at the bottom with a spacer line above them" {
    start_server
    [ "$(tmux_test show -gv status-position)" = "bottom" ]
    [ "$(tmux_test show -gv status)" = "2" ]
    spacer="$(tmux_test show -gv 'status-format[0]')"
    # half-height spacer: lower-half blocks in the bar color on the base color
    [[ "$spacer" == *"fg=#121214"* && "$spacer" == *"bg=#0B0B0C"* && "$spacer" == *"▄"* && "$spacer" == *"client_width"* ]]
    tabs="$(tmux_test show -gv 'status-format[1]')"
    [[ "$tabs" == *"window-status-format"* && "$tabs" == *"window-status-current-format"* ]]
    [[ "$tabs" == *"range=window"* ]]
    [[ "$tabs" == *"E:window-status-separator"* ]]
}

@test "tmux: the status bar has no side margins, so it lines up with the Neovim statusline" {
    start_server
    [ -z "$(tmux_test show -gv status-left)" ]
    right="$(tmux_test show -gv status-right)"
    # the session block is the last thing on the line: nothing after its own padding
    [[ "$right" == *"#S " ]]
}

@test "ghostty keeps the usual padding on top and sides but none at the bottom, so the tmux bar sits close to the edge" {
    grep -qxF 'window-padding-y = 14,0' "$PROJECT_ROOT/configs/ghostty/config"
}

@test "tmux: inactive tabs are gray blocks and the active tab is amber from index to name" {
    start_server
    other="$(tmux_test show -gv window-status-format)"
    current="$(tmux_test show -gv window-status-current-format)"
    [[ "$other" == *"bg=#18181B"* ]]
    [[ "$current" == *"bg=#F5A623"* ]]
    # index and name are amber: the first gray background comes only after the name, in the arrow
    before="${current%%bg=#18181B*}"
    [[ "$before" == *"#I"* && "$before" == *"#W"* ]]
}

@test "tmux: corners are square: no rounded caps and no rounded popup or menu borders" {
    run env LC_ALL=C.UTF-8 grep -nP '[\x{e0b4}\x{e0b6}\x{e0b2}]' "$CONF"
    [ "$status" -eq 1 ]
    run grep -nE 'border-lines rounded' "$CONF"
    [ "$status" -eq 1 ]
}

@test "tmux: every tab ends in a pointed arrow, with a thin chevron between neighbors of the same color" {
    start_server
    arrow="$(printf '\xee\x82\xb0')"
    chevron="$(printf '\xee\x82\xb1')"
    other="$(tmux_test show -gv window-status-format)"
    current="$(tmux_test show -gv window-status-current-format)"
    [[ "$other" == *"$arrow"* && "$other" == *"$chevron"* && "$other" == *"active_window_index"* && "$other" == *"window_end_flag"* ]]
    [[ "$current" == *"$arrow"* && "$current" == *"window_end_flag"* ]]
    [ -z "$(tmux_test show -gv window-status-separator)" ]
}

@test "tmux colors come from the theme sources" {
    pal="$PROJECT_ROOT/configs/noctalia/palettes/Terminal Noir.json"
    syn="$PROJECT_ROOT/configs/themes/terminal-noir/syntax.json"
    for hex in $(grep -oE '#[0-9a-fA-F]{6}' "$CONF" | tr 'A-F' 'a-f' | sort -u); do
        grep -qi "$hex" "$pal" "$syn"
    done
}

@test "terminal configs hold no personal data or portuguese" {
    run grep -rnE "nando""moreira|@gmail|/home/[a-z]|[áàâãéêíóôõúç]" \
        "$PROJECT_ROOT/configs/ghostty/config" \
        "$PROJECT_ROOT/configs/ghostty/overrides.conf" \
        "$PROJECT_ROOT/configs/tmux" \
        "$PROJECT_ROOT/configs/bat/config" \
        "$PROJECT_ROOT/configs/micro/settings.json" \
        "$PROJECT_ROOT/configs/micro/bindings.json"
    [ "$status" -ne 0 ]
}

@test "the ghostty config names both theme files" {
    grep -q 'theme = light:terminal-noir-light,dark:terminal-noir-dark' "$PROJECT_ROOT/configs/ghostty/config"
    [ -f "$PROJECT_ROOT/configs/ghostty/themes/terminal-noir-dark" ]
    [ -f "$PROJECT_ROOT/configs/ghostty/themes/terminal-noir-light" ]
}
