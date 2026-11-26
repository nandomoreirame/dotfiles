#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../../../bin/utils/noctalia-to-icebar"

@test "help describes how to return to Noctalia" {
    run bash "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == Usage:* ]]
    [[ "$output" == *Ctrl+C* ]]
}

@test "an unknown option is a usage error" {
    run bash "$SCRIPT" --unknown
    [ "$status" -eq 2 ]
}

@test "a missing config is rejected before accessing the desktop" {
    run bash "$SCRIPT" --config "$BATS_TEST_TMPDIR/missing.ron"
    [ "$status" -eq 1 ]
    [[ "$output" == *'Cannot read config'* ]]
}

@test "dry run does not require a desktop session" {
    run env -u WAYLAND_DISPLAY bash "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *'Restore Noctalia'* ]]
}

setup() {
    export XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR"
    export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
    export WAYLAND_DISPLAY=wayland-test
    export BASH_ENV=/dev/null
    export PATH="$BATS_TEST_TMPDIR:$PATH"
}

mock_session() {
    cp "$(command -v sleep)" "$BATS_TEST_TMPDIR/noctalia"
    "$BATS_TEST_TMPDIR/noctalia" 60 &
    export MOCK_NOCTALIA_PID=$!
    cat > "$BATS_TEST_TMPDIR/fuser" <<'STUB'
#!/bin/bash
echo "$MOCK_NOCTALIA_PID"
STUB
    cat > "$BATS_TEST_TMPDIR/umbriel" <<'STUB'
#!/bin/bash
if [[ -f "$XDG_RUNTIME_DIR/ready" ]]; then
    printf 'top\ticebar\tHDMI-A-1\tyes\n'
fi
STUB
    cat > "$BATS_TEST_TMPDIR/setsid" <<'STUB'
#!/bin/bash
touch "$XDG_RUNTIME_DIR/restored"
STUB
    chmod +x "$BATS_TEST_TMPDIR"/{fuser,umbriel,setsid}
}

teardown() {
    if [[ -n "${MOCK_NOCTALIA_PID:-}" ]]; then
        kill "$MOCK_NOCTALIA_PID" 2>/dev/null || true
        wait "$MOCK_NOCTALIA_PID" 2>/dev/null || true
    fi
}

@test "Icebar startup failure leaves Noctalia running" {
    mock_session
    run bash "$SCRIPT" --icebar /usr/bin/false
    [ "$status" -eq 1 ]
    [[ "$output" == *'Icebar exited'* ]]
    kill -0 "$MOCK_NOCTALIA_PID"
    [ ! -e "$XDG_RUNTIME_DIR/restored" ]
}

@test "a mapped Icebar replaces Noctalia and restores it on exit" {
    mock_session
    cat > "$BATS_TEST_TMPDIR/icebar" <<'STUB'
#!/bin/bash
touch "$XDG_RUNTIME_DIR/ready"
for (( attempt = 0; attempt < 100; attempt++ )); do
    kill -0 "$MOCK_NOCTALIA_PID" 2>/dev/null || exit 0
    sleep 0.05
done
exit 1
STUB
    chmod +x "$BATS_TEST_TMPDIR/icebar"
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [ -e "$XDG_RUNTIME_DIR/restored" ]
    ! kill -0 "$MOCK_NOCTALIA_PID" 2>/dev/null
}

@test "an Icebar configuration warning leaves Noctalia running" {
    mock_session
    cat > "$BATS_TEST_TMPDIR/icebar" <<'STUB'
#!/bin/bash
echo 'WARNING: Config parse failed: invalid RON'
touch "$XDG_RUNTIME_DIR/ready"
exec sleep 1
STUB
    chmod +x "$BATS_TEST_TMPDIR/icebar"
    run bash "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" == *'Icebar reported a configuration warning'* ]]
    kill -0 "$MOCK_NOCTALIA_PID"
    [ ! -e "$XDG_RUNTIME_DIR/restored" ]
}
