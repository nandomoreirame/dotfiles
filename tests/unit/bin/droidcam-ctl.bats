#!/usr/bin/env bats

# Unit tests for bin/utils/droidcam-ctl
#
# Run:
#   ./tests/run-tests unit/bin/droidcam-ctl.bats
#
# Coverage:
#   - start connects droidcam-cli to the phone saved in ~/.config/droidcam
#   - start replaces a running session instead of stacking a second one
#   - start reports a failed connection
#   - stop ends the session and is a no-op when nothing runs
#
# `droidcam-cli` is stubbed in perl (async bash jobs ignore SIGINT/SIGTERM
# traps); `pkill` and `notify-send` are stubbed to log their calls.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/droidcam-ctl"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR" "$TEST_DIR/run" "$TEST_DIR/home/.cache"
    : > "$CALL_LOG"

    printf 'v4\nip=192.0.2.9\nport=4747\naudio=0\nvideo=1\nsize=640x480\n' > "$TEST_DIR/home/.config-droidcam"
    mkdir -p "$TEST_DIR/home/.config"
    mv "$TEST_DIR/home/.config-droidcam" "$TEST_DIR/home/.config/droidcam"

    cat > "$STUB_DIR/droidcam-cli" <<'STUB'
#!/usr/bin/perl
open(my $log, '>>', $ENV{CALL_LOG}); print $log "droidcam-cli @ARGV\n"; close($log);
exit 1 if $ENV{DROIDCAM_FAIL};
$SIG{TERM} = sub { exit 0 };
sleep 1 while 1;
STUB
    for c in pkill notify-send; do
        cat > "$STUB_DIR/$c" <<STUB
#!/usr/bin/env bash
echo "$c \$*" >> "\$CALL_LOG"
STUB
    done
    chmod +x "$STUB_DIR"/*

    export CALL_LOG TEST_DIR DROIDCAM_START_WAIT=0.5
    export HOME="$TEST_DIR/home"
    export XDG_RUNTIME_DIR="$TEST_DIR/run"
    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    if [ -f "$XDG_RUNTIME_DIR/droidcam-ctl.pid" ]; then
        kill "$(cat "$XDG_RUNTIME_DIR/droidcam-ctl.pid")" 2>/dev/null || true
    fi
    temp_del "$TEST_DIR"
}

@test "start connects to the ip and port saved by the droidcam client" {
    run "$SCRIPT" start
    [ "$status" -eq 0 ]
    grep -q "^droidcam-cli .* 192.0.2.9 4747" "$CALL_LOG"
    grep -q -- "-nocontrols" "$CALL_LOG"
    kill -0 "$(cat "$XDG_RUNTIME_DIR/droidcam-ctl.pid")"
}

@test "start closes the droidcam GUI that would hold the device" {
    run "$SCRIPT" start
    grep -q "^pkill -x droidcam$" "$CALL_LOG"
}

@test "start twice keeps a single session" {
    run "$SCRIPT" start
    first="$(cat "$XDG_RUNTIME_DIR/droidcam-ctl.pid")"
    run "$SCRIPT" start
    [ "$status" -eq 0 ]
    ! kill -0 "$first" 2>/dev/null
    kill -0 "$(cat "$XDG_RUNTIME_DIR/droidcam-ctl.pid")"
}

@test "start reports a failed connection" {
    DROIDCAM_FAIL=1 run "$SCRIPT" start
    [ "$status" -eq 1 ]
    grep -q "^notify-send .*failed to connect" "$CALL_LOG"
    [ ! -e "$XDG_RUNTIME_DIR/droidcam-ctl.pid" ]
}

@test "stop ends the session and removes the pid file" {
    run "$SCRIPT" start
    pid="$(cat "$XDG_RUNTIME_DIR/droidcam-ctl.pid")"
    run "$SCRIPT" stop
    [ "$status" -eq 0 ]
    ! kill -0 "$pid" 2>/dev/null
    [ ! -e "$XDG_RUNTIME_DIR/droidcam-ctl.pid" ]
}

@test "stop with nothing running succeeds" {
    run "$SCRIPT" stop
    [ "$status" -eq 0 ]
}

@test "rejects an unknown action" {
    run "$SCRIPT" nope
    [ "$status" -eq 2 ]
}
