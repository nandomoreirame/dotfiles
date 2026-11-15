#!/usr/bin/env bats

# Unit tests for bin/utils/niri-screenshot-notify
#
# Run:
#   ./tests/run-tests unit/bin/niri-screenshot-notify.bats
#
# Why the watcher exists: niri's own "Screenshot captured" notification has no
# actions, so clicking it does nothing. The watcher listens for niri's
# ScreenshotCaptured event and sends a clickable notification through
# notify-open; a Noctalia filter hides niri's original one.
#
# Coverage:
#   - A saved screenshot produces a clickable notification for its path
#   - A clipboard-only screenshot (path null) still gets a plain notification
#   - Other niri events are ignored
#
# `niri` is stubbed: `event-stream` prints FAKE_EVENTS and exits (the watcher
# runs once with NIRI_SCREENSHOT_NOTIFY_ONCE=1). notify-open runs for real
# against stubbed `notify-send`, `xdg-open` and `nautilus`.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/niri-screenshot-notify"

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
    *) echo "niri $*" >> "$CALL_LOG" ;;
esac
STUB
    for tool in notify-send xdg-open nautilus; do
        printf '#!/usr/bin/env bash\necho "%s $*" >> "$CALL_LOG"\n' "$tool" > "$STUB_DIR/$tool"
    done
    chmod +x "$STUB_DIR"/*

    SHOT="$TEST_DIR/Screenshot from 2026-10-29 10-00-00.png"
    touch "$SHOT"

    export CALL_LOG
    export NIRI_SCREENSHOT_NOTIFY_ONCE=1
    export XDG_RUNTIME_DIR="$TEST_DIR"
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "a saved screenshot gets a clickable notification for its file" {
    export FAKE_EVENTS="{\"ScreenshotCaptured\":{\"path\":\"$SHOT\"}}"

    run timeout 5 "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(grep -c "^notify-send" "$CALL_LOG")" -eq 1 ]
    grep "^notify-send" "$CALL_LOG" | grep -q -- "--action=default=Open"
    grep "^notify-send" "$CALL_LOG" | grep -qF -- "-i $SHOT"
}

@test "a clipboard-only screenshot gets a plain notification" {
    export FAKE_EVENTS='{"ScreenshotCaptured":{"path":null}}'

    run timeout 5 "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(grep -c "^notify-send" "$CALL_LOG")" -eq 1 ]
    if grep "^notify-send" "$CALL_LOG" | grep -q -- "--action"; then return 1; fi
}

@test "ignores other niri events" {
    export FAKE_EVENTS='{"ConfigLoaded":{"failed":false}}
{"WindowFocusChanged":{"id":3}}'

    run timeout 5 "$SCRIPT"

    [ "$status" -eq 0 ]
    [ ! -s "$CALL_LOG" ]
}
