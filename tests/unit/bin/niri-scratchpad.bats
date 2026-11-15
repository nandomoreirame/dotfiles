#!/usr/bin/env bats

# Unit tests for bin/utils/niri-scratchpad
#
# Run:
#   ./tests/run-tests unit/bin/niri-scratchpad.bats
#
# Coverage (discord/spotify/localsend close to the tray; obsidian uses scratch):
#   - An unknown preset fails and advertises every known preset
#   - Toggling with no window launches the app (nothing to show/hide yet)
#   - Toggling a visible window sends it to the scratch workspace WITHOUT
#     stealing focus, which is the whole point of the emulated scratchpad
#   - Toggling a window parked in scratch brings it to the FOCUSED monitor
#     (never to a workspace index: niri indices repeat per output)
#   - The app-id match is anchored, so a lookalike app-id never hijacks the
#     toggle (it would hide an unrelated window instead of opening Discord)
#
# `niri` and `setsid` are stubbed on PATH: the stub niri answers the three
# --json queries from FAKE_* and records every `msg action` call, and the stub
# setsid records the launch command instead of spawning the real app.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/niri-scratchpad"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/niri" <<'STUB'
#!/usr/bin/env bash
echo "niri $*" >> "$CALL_LOG"
if [ "$1" = "msg" ] && [ "$2" = "--json" ]; then
    case "$3" in
        windows)
            if [ -n "${FAKE_WINDOWS_AFTER_LAUNCH:-}" ] && grep -q '^setsid ' "$CALL_LOG"; then
                printf '%s\n' "$FAKE_WINDOWS_AFTER_LAUNCH"
            else
                printf '%s\n' "$FAKE_WINDOWS"
            fi ;;
        workspaces) printf '%s\n' "$FAKE_WORKSPACES" ;;
        focused-output) printf '%s\n' "$FAKE_FOCUSED_OUTPUT" ;;
    esac
fi
exit 0
STUB

    cat > "$STUB_DIR/wl-paste" <<'STUB'
#!/usr/bin/env bash
[ -n "${FAKE_CLIPBOARD:-}" ] || exit 1
printf '%s' "$FAKE_CLIPBOARD"
STUB

    cat > "$STUB_DIR/setsid" <<'STUB'
#!/usr/bin/env bash
echo "setsid $*" >> "$CALL_LOG"
exit 0
STUB

    chmod +x "$STUB_DIR"/*
}

teardown() {
    temp_del "$TEST_DIR"
}

# Runs the script with a scrubbed environment. `env -i` is required: BASH_ENV
# points at ~/.bashrc here, which re-prepends PATH and would shadow the stubs.
run_scratchpad() {
    run env -i \
        HOME="$TEST_DIR" \
        PATH="$STUB_DIR:/usr/bin:/bin" \
        CALL_LOG="$CALL_LOG" \
        FAKE_WINDOWS="${FAKE_WINDOWS:-[]}" \
        FAKE_WINDOWS_AFTER_LAUNCH="${FAKE_WINDOWS_AFTER_LAUNCH:-}" \
        FAKE_WORKSPACES="${FAKE_WORKSPACES:-[]}" \
        FAKE_FOCUSED_OUTPUT="${FAKE_FOCUSED_OUTPUT:-{\"name\":\"eDP-1\"\}}" \
        FAKE_CLIPBOARD="${FAKE_CLIPBOARD:-}" \
        bash "$SCRIPT" "$@"
}

# `scratchpad_launch` backgrounds setsid, so the stub's append can land after
# the script exits. Poll instead of asserting on the log immediately.
wait_for_call() {
    local pattern="$1" i
    for ((i = 0; i < 30; i++)); do
        grep -qF -- "$pattern" "$CALL_LOG" && return 0
        command sleep 0.1
    done
    return 1
}

@test "an unknown preset fails and lists discord among the known presets" {
    run_scratchpad toggle nope

    assert_failure
    assert_output --partial "unknown preset 'nope'"
    assert_output --partial "discord"
}

@test "discord toggle launches the app when no window exists" {
    FAKE_WINDOWS='[]' run_scratchpad toggle discord

    assert_success
    run wait_for_call "setsid discord"
    assert_success
}

@test "a lookalike app-id never hijacks the discord toggle" {
    # Anchored match: an unrelated window whose app-id merely CONTAINS discord
    # must not be hidden in place of launching Discord.
    FAKE_WINDOWS='[{"id":3,"app_id":"discord-overlay-helper","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle discord

    assert_success
    run grep -cF -- "move-window-to-workspace" "$CALL_LOG"
    assert_output "0"
    run wait_for_call "setsid discord"
    assert_success
}

@test "an unknown preset lists localsend among the known presets" {
    run_scratchpad toggle nope

    assert_failure
    assert_output --partial "localsend"
}

@test "localsend toggle relaunches the app when it sits in the tray (no window)" {
    # Autostarted with --hidden: the process runs but has no window. LocalSend is
    # single-instance, so relaunching reopens the tray instance's window.
    FAKE_WINDOWS='[]' run_scratchpad toggle localsend

    assert_success
    run wait_for_call "setsid localsend"
    assert_success
}

@test "localsend toggle closes a visible window back to the tray, never into scratch" {
    # The close button sends LocalSend to the tray; the toggle must do the same
    # instead of parking the window in the scratch workspace.
    FAKE_WINDOWS='[{"id":5,"app_id":"localsend","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle localsend

    assert_success
    run grep -F -- "close-window --id 5" "$CALL_LOG"
    assert_success
    run grep -cF -- "move-window-to-workspace" "$CALL_LOG"
    assert_output "0"
}

@test "localsend toggle closes to the tray even a window left in scratch" {
    # A window parked by an older toggle must not be revealed: one press, tray.
    FAKE_WINDOWS='[{"id":5,"app_id":"localsend","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":1,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle localsend

    assert_success
    run grep -F -- "close-window --id 5" "$CALL_LOG"
    assert_success
    run grep -cF -- "move-window-to-monitor" "$CALL_LOG"
    assert_output "0"
}

@test "a lookalike app-id never hijacks the localsend toggle" {
    FAKE_WINDOWS='[{"id":3,"app_id":"localsend-helper","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle localsend

    assert_success
    run grep -cF -- "close-window" "$CALL_LOG"
    assert_output "0"
    run wait_for_call "setsid localsend"
    assert_success
}

@test "discord toggle closes a visible window back to the tray, never into scratch" {
    FAKE_WINDOWS='[{"id":7,"app_id":"discord","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle discord

    assert_success
    run grep -F -- "close-window --id 7" "$CALL_LOG"
    assert_success
    run grep -cF -- "move-window-to-workspace" "$CALL_LOG"
    assert_output "0"
}

@test "discord toggle closes to the tray even a window left in scratch" {
    FAKE_WINDOWS='[{"id":7,"app_id":"discord","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":1,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle discord

    assert_success
    run grep -F -- "close-window --id 7" "$CALL_LOG"
    assert_success
    run grep -cF -- "move-window-to-monitor" "$CALL_LOG"
    assert_output "0"
}

@test "spotify toggle closes a visible window back to the tray, never into scratch" {
    FAKE_WINDOWS='[{"id":8,"app_id":"Spotify","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle spotify

    assert_success
    run grep -F -- "close-window --id 8" "$CALL_LOG"
    assert_success
    run grep -cF -- "move-window-to-workspace" "$CALL_LOG"
    assert_output "0"
}

@test "spotify toggle closes to the tray even a window left in scratch" {
    FAKE_WINDOWS='[{"id":8,"app_id":"Spotify","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":1,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle spotify

    assert_success
    run grep -F -- "close-window --id 8" "$CALL_LOG"
    assert_success
    run grep -cF -- "move-window-to-monitor" "$CALL_LOG"
    assert_output "0"
}

@test "spotify toggle relaunches the app when it sits in the tray (no window)" {
    FAKE_WINDOWS='[]' run_scratchpad toggle spotify

    assert_success
    run wait_for_call "setsid spotify-launcher"
    assert_success
}

@test "obsidian toggle still hides into scratch, never closes the window" {
    FAKE_WINDOWS='[{"id":4,"app_id":"obsidian","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle obsidian

    assert_success
    run grep -F -- "move-window-to-workspace" "$CALL_LOG"
    assert_success
    assert_output --partial "--window-id 4"
    run grep -cF -- "close-window" "$CALL_LOG"
    assert_output "0"
}

@test "obsidian 1.15 (app-id md.obsidian.Obsidian) is found, never relaunched" {
    FAKE_WINDOWS='[{"id":4,"app_id":"md.obsidian.Obsidian","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle obsidian

    assert_success
    run grep -F -- "move-window-to-workspace" "$CALL_LOG"
    assert_success
    assert_output --partial "--window-id 4"
    run grep -cF -- "setsid obsidian" "$CALL_LOG"
    assert_output "0"
}

@test "obsidian toggle reveals a scratched window on the focused monitor" {
    FAKE_WINDOWS='[{"id":4,"app_id":"obsidian","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":1,"name":"scratch","is_focused":false}]' \
    FAKE_FOCUSED_OUTPUT='{"name":"HDMI-A-1"}' \
        run_scratchpad toggle obsidian

    assert_success
    run grep -F -- "move-window-to-monitor" "$CALL_LOG"
    assert_success
    assert_output --partial "--id 4 HDMI-A-1"
    run grep -F -- "focus-window --id 4" "$CALL_LOG"
    assert_success
}

@test "obsidian reveal keeps its tiled column where niri placed it (no centering)" {
    # center-window scrolls the strip, shifting the columns beside the 1/3 column.
    FAKE_WINDOWS='[{"id":4,"app_id":"md.obsidian.Obsidian","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":1,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle obsidian

    assert_success
    run grep -cF -- "center-window" "$CALL_LOG"
    assert_output "0"
}

@test "whatsapp reveal still centers the floating window" {
    FAKE_WINDOWS='[{"id":5,"app_id":"chrome-web.whatsapp.com__-Default","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":1,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle whatsapp

    assert_success
    run grep -F -- "center-window --id 5" "$CALL_LOG"
    assert_success
}

@test "the niri rule opens obsidian tiled at 1/3 of the screen" {
    local rule
    rule="$(grep -A6 -F 'md\.obsidian\.Obsidian' "$PROJECT_ROOT/configs/niri/config.kdl" | sed '/^}/q')"

    assert_regex "$rule" 'default-column-width \{ proportion 0\.33333; \}'
    refute_regex "$rule" 'open-floating true'
}

@test "x-post toggle launches the X composer when no window exists" {
    FAKE_WINDOWS='[]' run_scratchpad toggle x-post

    assert_success
    run wait_for_call "setsid google-chrome-stable --app=https://x.com/compose/post"
    assert_success
}

@test "x-post toggle closes an open composer instead of stacking another" {
    FAKE_WINDOWS='[{"id":9,"app_id":"chrome-x.com__compose_post-Default","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle x-post

    assert_success
    run grep -F -- "close-window --id 9" "$CALL_LOG"
    assert_success
    run grep -cF -- "setsid" "$CALL_LOG"
    assert_output "0"
}

@test "x-post toggle ignores the regular X.com webapp window" {
    # The tiled x.com/home webapp shares the host but not the composer path.
    FAKE_WINDOWS='[{"id":4,"app_id":"chrome-x.com__home-Default","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle x-post

    assert_success
    run grep -cF -- "close-window" "$CALL_LOG"
    assert_output "0"
    run wait_for_call "setsid google-chrome-stable --app=https://x.com/compose/post"
    assert_success
}

@test "x-post prefills the composer with the URL-encoded clipboard text" {
    FAKE_WINDOWS='[]' FAKE_CLIPBOARD='hello & "world"?' run_scratchpad toggle x-post

    assert_success
    run wait_for_call "setsid google-chrome-stable --app=https://x.com/compose/post?text=hello%20%26%20%22world%22%3F"
    assert_success
}

@test "x-post opens an empty composer when the clipboard has no text" {
    # An image-only clipboard makes `wl-paste --type text/plain` fail.
    FAKE_WINDOWS='[]' FAKE_CLIPBOARD='' run_scratchpad toggle x-post

    assert_success
    run wait_for_call "setsid google-chrome-stable --app=https://x.com/compose/post"
    assert_success
    run grep -cF -- "?text=" "$CALL_LOG"
    assert_output "0"
}

@test "an unknown preset lists grok among the known presets" {
    run_scratchpad toggle nope

    assert_failure
    assert_output --partial "grok"
}

@test "grok toggle launches the AppImage when no window exists" {
    FAKE_WINDOWS='[]' run_scratchpad toggle grok

    assert_success
    run wait_for_call "setsid $TEST_DIR/.local/share/grok-bot/appimage"
    assert_success
}

@test "grok toggle hides a visible window into scratch, never closes it" {
    FAKE_WINDOWS='[{"id":6,"app_id":"grok-bot","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle grok

    assert_success
    run grep -F -- "move-window-to-workspace" "$CALL_LOG"
    assert_success
    assert_output --partial "--window-id 6"
    run grep -cF -- "close-window" "$CALL_LOG"
    assert_output "0"
}

@test "a lookalike app-id never hijacks the grok toggle" {
    FAKE_WINDOWS='[{"id":3,"app_id":"grok-bot-helper","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle grok

    assert_success
    run grep -cF -- "move-window-to-workspace" "$CALL_LOG"
    assert_output "0"
    run wait_for_call "setsid $TEST_DIR/.local/share/grok-bot/appimage"
    assert_success
}

@test "grok forces the window floating after launch (its app-id arrives after map)" {
    # Electron/Tauri apps set the app-id after the window maps, so the niri
    # open-floating rule misses them; the helper floats the window itself.
    FAKE_WINDOWS='[]' \
    FAKE_WINDOWS_AFTER_LAUNCH='[{"id":9,"app_id":"grok-bot","workspace_id":2}]' \
        run_scratchpad toggle grok

    assert_success
    run grep -F -- "move-window-to-floating --id 9" "$CALL_LOG"
    assert_success
}

@test "grok forces a tiled window floating when it is revealed from scratch" {
    FAKE_WINDOWS='[{"id":6,"app_id":"grok-bot","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":2,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle grok

    assert_success
    run grep -F -- "move-window-to-floating --id 6" "$CALL_LOG"
    assert_success
}

@test "obsidian is never forced floating (it lives tiled in a 1/3 column)" {
    FAKE_WINDOWS='[{"id":4,"app_id":"obsidian","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":2,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle obsidian

    assert_success
    run grep -cF -- "move-window-to-floating" "$CALL_LOG"
    assert_output "0"
}

@test "grok reveal does not open a bot deep link" {
    FAKE_WINDOWS='[{"id":6,"app_id":"grok-bot","workspace_id":9}]' \
    FAKE_WORKSPACES='[{"id":9,"idx":2,"name":"scratch","is_focused":false}]' \
        run_scratchpad toggle grok

    assert_success
    run grep -cF -- "xdg-open" "$CALL_LOG"
    assert_output "0"
}

@test "grok launch passes no deep link argument" {
    FAKE_WINDOWS='[]' run_scratchpad toggle grok

    assert_success
    run wait_for_call "setsid $TEST_DIR/.local/share/grok-bot/appimage"
    assert_success
    run grep -cF -- "grokbot://" "$CALL_LOG"
    assert_output "0"
}

@test "grok hide never touches the deep link" {
    FAKE_WINDOWS='[{"id":6,"app_id":"grok-bot","workspace_id":2}]' \
    FAKE_WORKSPACES='[{"id":2,"idx":1,"name":null,"is_focused":true}]' \
        run_scratchpad toggle grok

    assert_success
    run grep -cF -- "xdg-open" "$CALL_LOG"
    assert_output "0"
}
