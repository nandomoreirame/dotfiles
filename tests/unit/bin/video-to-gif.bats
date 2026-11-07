#!/usr/bin/env bats

# Unit tests for bin/utils/video-to-gif
#
# Run:
#   ./tests/run-tests unit/bin/video-to-gif.bats
#
# Coverage:
#   - With no argument it converts the newest recording_*.mp4 (the Ctrl+Alt+1
#     videos) and ignores the gif_*.mp4 intermediates of the GIF mode
#   - An explicit input (and optional output) is honored
#   - The ffmpeg call uses the palettegen/paletteuse pair (no washed-out GIF)
#   - The GIF path lands on the clipboard
#   - Missing input fails with a notification instead of calling ffmpeg
#
# `ffmpeg`, `notify-send`, `wl-copy` and `xdg-user-dir` are stubbed on PATH.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/video-to-gif"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"
    REC_DIR="$TEST_DIR/Videos/Recordings"

    mkdir -p "$STUB_DIR" "$REC_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/ffmpeg" <<'STUB'
#!/usr/bin/env bash
echo "ffmpeg $*" >> "$CALL_LOG"
: > "${!#}"
STUB
    cat > "$STUB_DIR/notify-send" <<'STUB'
#!/usr/bin/env bash
echo "notify-send $*" >> "$CALL_LOG"
STUB
    cat > "$STUB_DIR/wl-copy" <<'STUB'
#!/usr/bin/env bash
echo "wl-copy $*" >> "$CALL_LOG"
STUB
    cat > "$STUB_DIR/xdg-user-dir" <<'STUB'
#!/usr/bin/env bash
echo "$TEST_DIR/Videos"
STUB
    chmod +x "$STUB_DIR"/*

    export CALL_LOG TEST_DIR
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "converts the newest recording when called without arguments" {
    touch "$REC_DIR/recording_2026-10-25_10-00-00.mp4"
    touch "$REC_DIR/recording_2026-10-26_09-00-00.mp4"

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    grep -q -- "-i $REC_DIR/recording_2026-10-26_09-00-00.mp4 " "$CALL_LOG"
    [ -f "$REC_DIR/recording_2026-10-26_09-00-00.gif" ]
}

@test "ignores the gif_*.mp4 intermediates of the GIF mode" {
    touch "$REC_DIR/recording_2026-10-25_10-00-00.mp4"
    touch "$REC_DIR/gif_2026-10-26_09-00-00.mp4"

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    grep -q -- "-i $REC_DIR/recording_2026-10-25_10-00-00.mp4 " "$CALL_LOG"
}

@test "honors an explicit input and output" {
    touch "$TEST_DIR/clip.mp4"

    run "$SCRIPT" "$TEST_DIR/clip.mp4" "$TEST_DIR/out.gif"

    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/out.gif" ]
}

@test "builds a palette so the GIF keeps its colors" {
    touch "$REC_DIR/recording_2026-10-26_09-00-00.mp4"

    run "$SCRIPT"

    grep -q "palettegen" "$CALL_LOG"
    grep -q "paletteuse" "$CALL_LOG"
}

@test "copies the GIF path to the clipboard" {
    touch "$REC_DIR/recording_2026-10-26_09-00-00.mp4"

    run "$SCRIPT"

    grep -qx "wl-copy $REC_DIR/recording_2026-10-26_09-00-00.gif" "$CALL_LOG"
}

@test "fails with a notification when there is no recording" {
    run "$SCRIPT"

    [ "$status" -ne 0 ]
    if grep -q "^ffmpeg" "$CALL_LOG"; then return 1; fi
    grep -q "^notify-send" "$CALL_LOG"
}

@test "fails when the given input does not exist" {
    run "$SCRIPT" "$TEST_DIR/missing.mp4"

    [ "$status" -ne 0 ]
    if grep -q "^ffmpeg" "$CALL_LOG"; then return 1; fi
}

@test "the saved notification opens the GIF when clicked" {
    touch "$REC_DIR/recording_2026-10-26_09-00-00.mp4"

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    grep "^notify-send" "$CALL_LOG" | grep -q -- "--action=default=Open"
    grep "^notify-send" "$CALL_LOG" | grep -qF "GIF saved"
}
