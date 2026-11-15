#!/usr/bin/env bats

# Unit tests for bin/utils/noctalia-restart
#
# Run:
#   ./tests/run-tests tests/unit/bin/noctalia-restart.bats
#
# Restarts Noctalia: kills `noctalia` by PID from pgrep -x, reaps cliphist
# watchers, then spawns `noctalia` via niri (setsid fallback). A stray `qs`
# is never touched. Stubs pgrep/kill/niri/setsid.
# `env -i` is required: BASH_ENV re-prepends PATH and would shadow the stubs.

load '../../bats/helpers/setup'
bats_require_minimum_version 1.5.0

SCRIPT="$PROJECT_ROOT/bin/utils/noctalia-restart"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    PROC_DIR="$TEST_DIR/proc"
    CALL_LOG="$TEST_DIR/calls.log"

    RUNTIME_DIR="$TEST_DIR/runtime"
    mkdir -p "$RUNTIME_DIR"
    : > "$RUNTIME_DIR/niri.wayland-1.42.sock"
    mkdir -p "$STUB_DIR" "$PROC_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/pgrep" <<'STUB'
#!/usr/bin/env bash
# Answer pgrep -x qs|noctalia|niri|wl-paste from FAKE_*_PIDS.
# Optional FAKE_*_ALIVE_ROUNDS: report PIDs for the first N calls, then gone.
pgrep_count_and_alive() {
    local name="$1"
    local pids="$2"
    local rounds="${3:-}"
    local counter="$TEST_DIR/pgrep-${name}.count"
    local n=0
    if [ -f "$counter" ]; then
        n=$(cat "$counter")
    fi
    n=$((n + 1))
    printf '%s\n' "$n" >"$counter"

    if [ -z "$pids" ]; then
        echo "pgrep -x $name (gone)" >>"$CALL_LOG"
        exit 1
    fi
    if [ -n "$rounds" ] && [ "$n" -gt "$rounds" ]; then
        echo "pgrep -x $name (gone)" >>"$CALL_LOG"
        exit 1
    fi
    if grep -qE "niri msg action spawn|setsid" "$CALL_LOG" 2>/dev/null; then
        echo "SPAWNED_TOO_EARLY" >>"$CALL_LOG"
    fi
    echo "pgrep -x $name (alive)" >>"$CALL_LOG"
    # shellcheck disable=SC2086
    printf '%s\n' $pids
    exit 0
}

if [ "$1" = "-x" ]; then
    case "$2" in
    qs)
        pgrep_count_and_alive qs "${FAKE_QS_PIDS:-}" "${FAKE_QS_ALIVE_ROUNDS:-}"
        ;;
    noctalia)
        pgrep_count_and_alive noctalia "${FAKE_NOCTALIA_PIDS:-}" "${FAKE_NOCTALIA_ALIVE_ROUNDS:-}"
        ;;
    niri)
        if [ -n "${FAKE_NIRI_PIDS:-}" ]; then
            echo "pgrep -x niri (alive)" >>"$CALL_LOG"
            # shellcheck disable=SC2086
            printf '%s\n' $FAKE_NIRI_PIDS
            exit 0
        fi
        echo "pgrep -x niri (gone)" >>"$CALL_LOG"
        exit 1
        ;;
    wl-paste)
        if [ -n "${FAKE_WL_PASTE_PIDS:-}" ]; then
            echo "pgrep -x wl-paste (alive)" >>"$CALL_LOG"
            # shellcheck disable=SC2086
            printf '%s\n' $FAKE_WL_PASTE_PIDS
            exit 0
        fi
        echo "pgrep -x wl-paste (gone)" >>"$CALL_LOG"
        exit 1
        ;;
    esac
fi
exit 1
STUB

    cat > "$STUB_DIR/kill" <<'STUB'
#!/usr/bin/env bash
if [ "$#" -eq 0 ]; then
    echo "kill" >> "$CALL_LOG"
else
    echo "kill $*" >> "$CALL_LOG"
fi
exit 0
STUB

    cat > "$STUB_DIR/niri" <<'STUB'
#!/usr/bin/env bash
# A niri reachable only through an existing socket path (FAKE_NIRI_DOWN=1 = unreachable).
if [ -n "${FAKE_NIRI_DOWN:-}" ] || [ ! -e "${NIRI_SOCKET:-/nonexistent}" ]; then
    echo "niri UNREACHABLE $*" >> "$CALL_LOG"
    exit 1
fi
if [ "$1 $2" = "msg version" ]; then
    exit 0
fi
if [ "$*" = "msg --json windows" ]; then
    # Tray apps re-open their window when the tray host (noctalia) goes away.
    if grep -q "niri msg action spawn" "$CALL_LOG"; then
        echo "${FAKE_WINDOWS_AFTER:-[]}"
    else
        echo "${FAKE_WINDOWS_BEFORE:-[]}"
    fi
    exit 0
fi
echo "niri $*" >> "$CALL_LOG"
echo "NIRI_SOCKET=$NIRI_SOCKET" >> "$CALL_LOG"
exit 0
STUB

    cat > "$STUB_DIR/busctl" <<'STUB'
#!/usr/bin/env bash
# The tray host (StatusNotifierWatcher) is back once noctalia was spawned,
# unless FAKE_WATCHER_DOWN=1.
[ "$*" = "--user status org.kde.StatusNotifierWatcher" ] || exit 1
[ -z "${FAKE_WATCHER_DOWN:-}" ] && grep -q "niri msg action spawn" "$CALL_LOG"
STUB

    cat > "$STUB_DIR/setsid" <<'STUB'
#!/usr/bin/env bash
if [ "$#" -eq 0 ]; then
    echo "setsid" >> "$CALL_LOG"
else
    echo "setsid $*" >> "$CALL_LOG"
fi
exit 0
STUB

    # Fake cliphist watcher cmdline under NOCTALIA_PROC_DIR.
    mkdir -p "$PROC_DIR/9001"
    printf 'wl-paste --type text --watch cliphist store\0' >"$PROC_DIR/9001/cmdline"
    mkdir -p "$PROC_DIR/9002"
    printf 'wl-paste --type image\0' >"$PROC_DIR/9002/cmdline"

    chmod +x "$STUB_DIR"/*
}

teardown() {
    temp_del "$TEST_DIR"
}

# Runs the script with a scrubbed environment so stubs win on PATH.
run_restart() {
    local separate=()
    if [ "${1:-}" = "--separate-stderr" ]; then
        separate=(--separate-stderr)
        shift
    fi
    run "${separate[@]}" env -i \
        HOME="$TEST_DIR" \
        PATH="$STUB_DIR:/usr/bin:/bin" \
        CALL_LOG="$CALL_LOG" \
        XDG_RUNTIME_DIR="$RUNTIME_DIR" \
        NIRI_SOCKET="${NIRI_SOCKET_TEST-$RUNTIME_DIR/niri.wayland-1.42.sock}" \
        FAKE_NIRI_DOWN="${FAKE_NIRI_DOWN:-}" \
        TEST_DIR="$TEST_DIR" \
        NOCTALIA_PROC_DIR="$PROC_DIR" \
        NOCTALIA_RESTART_WAIT_SECS="${NOCTALIA_RESTART_WAIT_SECS:-0}" \
        NOCTALIA_RESTART_POLL_SECS="${NOCTALIA_RESTART_POLL_SECS:-0.05}" \
        FAKE_QS_PIDS="${FAKE_QS_PIDS:-}" \
        FAKE_NOCTALIA_PIDS="${FAKE_NOCTALIA_PIDS:-}" \
        FAKE_QS_ALIVE_ROUNDS="${FAKE_QS_ALIVE_ROUNDS:-}" \
        FAKE_NOCTALIA_ALIVE_ROUNDS="${FAKE_NOCTALIA_ALIVE_ROUNDS:-}" \
        FAKE_NIRI_PIDS="${FAKE_NIRI_PIDS-1}" \
        FAKE_WL_PASTE_PIDS="${FAKE_WL_PASTE_PIDS:-}" \
        FAKE_WINDOWS_BEFORE="${FAKE_WINDOWS_BEFORE:-}" \
        FAKE_WINDOWS_AFTER="${FAKE_WINDOWS_AFTER:-}" \
        FAKE_WATCHER_DOWN="${FAKE_WATCHER_DOWN:-}" \
        NOCTALIA_RESTART_TRAY_ROUNDS="${NOCTALIA_RESTART_TRAY_ROUNDS:-3}" \
        bash "$SCRIPT" "$@"
}

@test "with noctalia alive kills noctalia by PID, reaps cliphist watchers, spawns noctalia via niri" {
    FAKE_NOCTALIA_PIDS="2222"
    FAKE_WL_PASTE_PIDS="9001 9002"
    FAKE_NIRI_PIDS="1"

    run_restart

    assert_success
    grep -qx "kill 2222" "$CALL_LOG"
    # cliphist marker watcher is reaped; plain wl-paste is not
    grep -qx "kill 9001" "$CALL_LOG"
    ! grep -qx "kill 9002" "$CALL_LOG"
    grep -qx "niri msg action spawn -- noctalia" "$CALL_LOG"
    ! grep -q "setsid" "$CALL_LOG"
}

@test "a stray qs process is left alone" {
    FAKE_QS_PIDS="1111"
    FAKE_NOCTALIA_PIDS="2222"
    FAKE_NIRI_PIDS="1"

    run_restart

    assert_success
    grep -qx "kill 2222" "$CALL_LOG"
    ! grep -q "kill.* 1111" "$CALL_LOG"
    ! grep -q "pgrep -x qs" "$CALL_LOG"
}

@test "PID that never dies gets kill -9 before spawn" {
    FAKE_NOCTALIA_PIDS="5555"
    NOCTALIA_RESTART_WAIT_SECS=0
    FAKE_NIRI_PIDS="1"

    run_restart

    assert_success
    grep -qx "kill 5555" "$CALL_LOG"
    grep -qx "kill -9 5555" "$CALL_LOG"
    awk '
      /kill -9 5555/ { killed=1 }
      /niri msg action spawn -- noctalia$/ {
        if (!killed) exit 1
        found=1
      }
      END { exit found ? 0 : 1 }
    ' "$CALL_LOG"
}

@test "falls back to setsid when niri is not running" {
    FAKE_NOCTALIA_PIDS="1111"
    FAKE_NIRI_PIDS=""
    NOCTALIA_RESTART_WAIT_SECS=0

    run_restart

    assert_success
    grep -qx "kill 1111" "$CALL_LOG"
    grep -qx "setsid -f noctalia" "$CALL_LOG"
    ! grep -q "niri msg action spawn" "$CALL_LOG"
}

@test "game-mode has no v4 (qs) references" {
    [ -f "$PROJECT_ROOT/bin/utils/game-mode" ]
    ! grep -qw 'qs' "$PROJECT_ROOT/bin/utils/game-mode"
    # sys-shell-restart is not shipped in the public tree.
    [ ! -e "$PROJECT_ROOT/bin/sys/sys-shell-restart" ]
}

@test "game-mode keeps the noctalia shell unfrozen" {
    local re
    re="$(sed -n "s/^readonly KEEP_COMMS_RE='\\(.*\\)'$/\\1/p" "$PROJECT_ROOT/bin/utils/game-mode")"
    [ -n "$re" ]
    [[ "noctalia" =~ $re ]]
}

@test "noctalia-restart spawns noctalia directly, without noctalia-session" {
    ! grep -q 'noctalia-session' "$SCRIPT"
    ! grep -qw 'qs' "$SCRIPT"
}

@test "config.toml session_locked calls nocta media-pause" {
    local config="$PROJECT_ROOT/configs/noctalia/config.toml"
    [ -f "$config" ]
    grep -F 'session_locked' "$config" | grep -Fq '~/.dotfiles/bin/utils/nocta media-pause'
}

@test "stale NIRI_SOCKET is replaced by the live socket before spawning" {
    NIRI_SOCKET_TEST="$RUNTIME_DIR/niri.wayland-1.1464.sock"
    FAKE_NOCTALIA_PIDS="2222"

    run_restart

    assert_success
    grep -qx "NIRI_SOCKET=$RUNTIME_DIR/niri.wayland-1.42.sock" "$CALL_LOG"
    grep -qx "niri msg action spawn -- noctalia" "$CALL_LOG"
}

@test "niri running but unreachable aborts before killing the shell" {
    FAKE_NIRI_DOWN=1
    FAKE_NOCTALIA_PIDS="2222"

    run_restart --separate-stderr

    [ "$status" -ne 0 ]
    ! grep -q "^kill" "$CALL_LOG"
    [[ "$stderr" == *niri* ]]
}

@test "closes the Spotify window that the restart re-opened, after the tray is back" {
    FAKE_NOCTALIA_PIDS="2222"
    FAKE_WINDOWS_BEFORE='[{"id":5,"app_id":"ghostty"}]'
    FAKE_WINDOWS_AFTER='[{"id":5,"app_id":"ghostty"},{"id":141,"app_id":"Spotify"}]'

    run_restart

    assert_success
    grep -qx "niri msg action close-window --id 141" "$CALL_LOG"
    if grep -q "close-window --id 5" "$CALL_LOG"; then return 1; fi
    awk '/action spawn -- noctalia$/ { s=1 } /close-window/ { if (!s) exit 1; f=1 } END { exit f ? 0 : 1 }' "$CALL_LOG"
}

@test "keeps a Spotify window that was already open before the restart" {
    FAKE_NOCTALIA_PIDS="2222"
    FAKE_WINDOWS_BEFORE='[{"id":141,"app_id":"Spotify"}]'
    FAKE_WINDOWS_AFTER='[{"id":141,"app_id":"Spotify"}]'

    run_restart

    assert_success
    if grep -q "close-window" "$CALL_LOG"; then return 1; fi
}

@test "leaves the window open when the tray never comes back" {
    # Closing Spotify with no tray to hide in would quit it.
    FAKE_NOCTALIA_PIDS="2222"
    FAKE_WATCHER_DOWN=1
    FAKE_WINDOWS_AFTER='[{"id":141,"app_id":"Spotify"}]'

    run_restart

    assert_success
    if grep -q "close-window" "$CALL_LOG"; then return 1; fi
}
