#!/usr/bin/env bats

# Unit tests for bin/utils/notify-open
#
# Run:
#   ./tests/run-tests unit/bin/notify-open.bats
#
# Coverage:
#   - Clicking the notification (default action) opens the file
#   - "Show in folder" opens the file manager with the file selected
#   - "Delete" moves the file to the trash (gio trash), never rm
#   - A dismissed or expired notification opens nothing
#   - Images use themselves as the notification icon, other files a generic one
#
# `notify-send` is stubbed: it records its arguments and prints FAKE_ACTION,
# which is what `notify-send --wait` prints for the action the user picked.
# `xdg-open`, `nautilus` and `gio` are stubbed to record what would be opened
# or trashed.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/notify-open"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/notify-send" <<'STUB'
#!/usr/bin/env bash
echo "notify-send $*" >> "$CALL_LOG"
[ -n "${FAKE_ACTION:-}" ] && echo "$FAKE_ACTION"
exit 0
STUB
    for tool in xdg-open nautilus gio; do
        printf '#!/usr/bin/env bash\necho "%s $*" >> "$CALL_LOG"\n' "$tool" > "$STUB_DIR/$tool"
    done
    chmod +x "$STUB_DIR"/*

    IMAGE="$TEST_DIR/Screenshot from 2026-10-29 10-00-00.png"
    VIDEO="$TEST_DIR/recording_2026-10-29_10-00-00.mp4"
    touch "$IMAGE" "$VIDEO"

    export CALL_LOG FAKE_ACTION=""
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "offers open and show-in-folder actions and waits for the click" {
    run "$SCRIPT" "Screenshot saved" "$IMAGE"

    [ "$status" -eq 0 ]
    grep "^notify-send" "$CALL_LOG" | grep -q -- "--wait"
    grep "^notify-send" "$CALL_LOG" | grep -q -- "--action=default=Open"
    grep "^notify-send" "$CALL_LOG" | grep -q -- "--action=folder=Show in folder"
    grep "^notify-send" "$CALL_LOG" | grep -q -- "--action=delete=Delete"
}

@test "clicking the notification opens the file" {
    export FAKE_ACTION=default

    run "$SCRIPT" "Screenshot saved" "$IMAGE"

    [ "$status" -eq 0 ]
    grep -qxF "xdg-open $IMAGE" "$CALL_LOG"
}

@test "show-in-folder opens the file manager with the file selected" {
    export FAKE_ACTION=folder

    run "$SCRIPT" "Recording saved" "$VIDEO"

    [ "$status" -eq 0 ]
    grep -qxF "nautilus --select $VIDEO" "$CALL_LOG"
    if grep -q "^xdg-open" "$CALL_LOG"; then return 1; fi
}

@test "delete moves the file to the trash" {
    export FAKE_ACTION=delete

    run "$SCRIPT" "Recording saved" "$VIDEO"

    [ "$status" -eq 0 ]
    grep -qxF "gio trash -- $VIDEO" "$CALL_LOG"
    if grep -qE "^(xdg-open|nautilus)" "$CALL_LOG"; then return 1; fi
}

@test "a dismissed notification opens nothing" {
    run "$SCRIPT" "Screenshot saved" "$IMAGE"

    [ "$status" -eq 0 ]
    if grep -qE "^(xdg-open|nautilus|gio)" "$CALL_LOG"; then return 1; fi
}

@test "uses the image itself as icon and its file name as default body" {
    run "$SCRIPT" "Screenshot saved" "$IMAGE"

    grep "^notify-send" "$CALL_LOG" | grep -qF -- "-i $IMAGE"
    grep "^notify-send" "$CALL_LOG" | grep -qF "Screenshot from 2026-10-29 10-00-00.png"
}

@test "uses a generic icon for videos and keeps a custom body and app name" {
    run "$SCRIPT" -a "Screen Recorder" "Recording saved" "$VIDEO" "custom body"

    grep "^notify-send" "$CALL_LOG" | grep -qF -- "-a Screen Recorder"
    grep "^notify-send" "$CALL_LOG" | grep -qF -- "-i video-x-generic"
    grep "^notify-send" "$CALL_LOG" | grep -qF "custom body"
}

@test "rejects a call without summary and file" {
    run "$SCRIPT" "Screenshot saved"

    [ "$status" -eq 2 ]
    [ ! -s "$CALL_LOG" ]
}
