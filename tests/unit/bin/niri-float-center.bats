#!/usr/bin/env bats

# Unit tests for bin/utils/niri-float-center
#
# Run:
#   ./tests/run-tests unit/bin/niri-float-center.bats
#
# Why the watcher exists: Nautilus passes its window handle to Quick Preview
# (sushi), so niri treats the preview as a child and centers it on the Nautilus
# window, ignoring the window-rule's default-floating-position. The watcher
# re-centers matching windows on their output when they open.
#
# Coverage:
#   - A newly opened preview is moved to the center of ITS output
#   - Each window is centered once (focus changes re-emit the window)
#   - Other apps and tiled windows are ignored
#   - A window larger than the output is clamped to 0 (a negative value would
#     be read by niri as a relative move)
#
# `niri` is stubbed on PATH: `event-stream` prints FAKE_EVENTS and exits (the
# watcher runs once with NIRI_FLOAT_CENTER_ONCE=1), the JSON queries answer from
# fixtures, and `action` calls are recorded.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/niri-float-center"

PREVIEW='{"id":7,"app_id":"org.gnome.NautilusPreviewer","workspace_id":4,"is_floating":true}'

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/niri" <<'STUB'
#!/usr/bin/env bash
case "$*" in
    "msg --json event-stream") printf '%s\n' "$FAKE_EVENTS" ;;
    "msg --json workspaces") echo '[{"id":4,"output":"DP-1"},{"id":9,"output":"eDP-1"},{"id":3,"output":"HDMI-A-1"}]' ;;
    "msg --json outputs") echo '{"DP-1":{"logical":{"x":632,"y":1308,"width":1920,"height":1080}},"eDP-1":{"logical":{"x":0,"y":0,"width":1536,"height":864}},"HDMI-A-1":{"logical":{"x":2552,"y":1308,"width":2560,"height":1080}}}' ;;
    "msg --json windows")
        # move-floating-window coordinates are relative to the working area:
        # report the last move shifted down by FAKE_TOP (a top bar's height).
        read -r _ _ _ _ _ _ _ mx _ my < <(grep move-floating-window "$CALL_LOG" | tail -1)
        printf '[{"id":7,"layout":{"tile_size":[%s],"tile_pos_in_workspace_view":[%s.0,%s.0]}}]\n' \
            "$FAKE_SIZE" "${mx:-0}" "$(( ${my:-0} + FAKE_TOP ))"
        ;;
    *) echo "niri $*" >> "$CALL_LOG" ;;
esac
STUB
    chmod +x "$STUB_DIR/niri"

    export CALL_LOG
    export FAKE_SIZE="1202.0,722.0" FAKE_TOP=0
    export NIRI_FLOAT_CENTER_ONCE=1
    export XDG_RUNTIME_DIR="$TEST_DIR"
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    temp_del "$TEST_DIR"
}

opened() {
    printf '{"WindowOpenedOrChanged":{"window":%s}}' "$1"
}

@test "centers a newly opened preview on its output" {
    export FAKE_EVENTS="$(opened "$PREVIEW")"

    run timeout 5 "$SCRIPT"

    [ "$status" -eq 0 ]
    # (1920-1202)/2 = 359, (1080-722)/2 = 179
    grep -qx "niri msg action move-floating-window --id 7 -x 359 -y 179" "$CALL_LOG"
}

@test "uses the size of the output the window is on" {
    export FAKE_EVENTS="$(opened '{"id":7,"app_id":"org.gnome.NautilusPreviewer","workspace_id":9,"is_floating":true}')"

    run timeout 5 "$SCRIPT"

    # (1536-1202)/2 = 167, (864-722)/2 = 71
    grep -qx "niri msg action move-floating-window --id 7 -x 167 -y 71" "$CALL_LOG"
}

@test "centers each window only once" {
    export FAKE_EVENTS="$(opened "$PREVIEW")
$(opened "$PREVIEW")"

    run timeout 5 "$SCRIPT"

    [ "$(grep -c move-floating-window "$CALL_LOG")" -eq 1 ]
}

@test "ignores other apps and tiled windows" {
    export FAKE_EVENTS="$(opened '{"id":8,"app_id":"org.gnome.Nautilus","workspace_id":4,"is_floating":true}')
$(opened '{"id":7,"app_id":"org.gnome.NautilusPreviewer","workspace_id":4,"is_floating":false}')"

    run timeout 5 "$SCRIPT"

    [ "$status" -eq 0 ]
    [ ! -s "$CALL_LOG" ]
}

@test "clamps to zero when the window is larger than the output" {
    export FAKE_EVENTS="$(opened '{"id":7,"app_id":"org.gnome.NautilusPreviewer","workspace_id":9,"is_floating":true}')"
    export FAKE_SIZE="1700.0,900.0"

    run timeout 5 "$SCRIPT"

    grep -qx "niri msg action move-floating-window --id 7 -x 0 -y 0" "$CALL_LOG"
}

@test "centers inside the working area when a top bar shifts the coordinates" {
    export FAKE_EVENTS="$(opened '{"id":7,"app_id":"org.gnome.NautilusPreviewer","workspace_id":3,"is_floating":true}')"
    export FAKE_TOP=34

    run timeout 5 "$SCRIPT"

    # First move: (2560-1202)/2 = 679, (1080-722)/2 = 179, lands 34 px lower.
    # Correction: (1080-34-722)/2 = 162 inside the area below the bar.
    [ "$(grep -c move-floating-window "$CALL_LOG")" -eq 2 ]
    [ "$(grep move-floating-window "$CALL_LOG" | tail -1)" = "niri msg action move-floating-window --id 7 -x 679 -y 162" ]
}

@test "moves only once when nothing shifts the coordinates" {
    export FAKE_EVENTS="$(opened "$PREVIEW")"

    run timeout 5 "$SCRIPT"

    [ "$(grep -c move-floating-window "$CALL_LOG")" -eq 1 ]
}
