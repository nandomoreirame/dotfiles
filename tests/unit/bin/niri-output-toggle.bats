#!/usr/bin/env bats

# Unit tests for bin/utils/niri-output-toggle
#
# Run:
#   ./tests/run-tests unit/bin/niri-output-toggle.bats
#
# `niri` is stubbed on PATH: it answers `msg --json outputs` from FAKE_OUTPUTS
# and records every other call. An output is considered ON when niri reports a
# non-null `logical` block for it (a powered-off output has `logical: null`).

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/niri-output-toggle"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/niri" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "msg" ] && [ "$2" = "--json" ] && [ "$3" = "outputs" ]; then
    printf '%s\n' "$FAKE_OUTPUTS"
    exit 0
fi
echo "niri $*" >> "$CALL_LOG"
exit 0
STUB
    chmod +x "$STUB_DIR/niri"

    export CALL_LOG
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "turns the output off when it is active" {
    export FAKE_OUTPUTS='{"DP-1":{"name":"DP-1","logical":{"x":0,"y":0}}}'

    run "$SCRIPT" DP-1

    [ "$status" -eq 0 ]
    grep -qx "niri msg output DP-1 off" "$CALL_LOG"
}

@test "turns the output on when it is disabled" {
    export FAKE_OUTPUTS='{"DP-1":{"name":"DP-1","logical":null}}'

    run "$SCRIPT" DP-1

    [ "$status" -eq 0 ]
    grep -qx "niri msg output DP-1 on" "$CALL_LOG"
}

@test "fails without touching niri when the output is not connected" {
    export FAKE_OUTPUTS='{"HDMI-A-1":{"name":"HDMI-A-1","logical":{"x":0,"y":0}}}'

    run "$SCRIPT" DP-1

    [ "$status" -ne 0 ]
    [ ! -s "$CALL_LOG" ]
}

@test "requires an output name" {
    run "$SCRIPT"

    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}
