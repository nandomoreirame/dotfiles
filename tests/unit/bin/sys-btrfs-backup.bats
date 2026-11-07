#!/usr/bin/env bats

# Unit tests for bin/sys/sys-btrfs-backup
#
# Run:
#   ./tests/run-tests unit/bin/sys-btrfs-backup.bats
#
# Coverage:
#   - Incremental parent selection walks EVERY local snapshot until it finds
#     one that also exists on the remote host (regression: the ssh call inside
#     the while-read loop used to drain the pipe, so only the newest candidate
#     was ever probed and every run degraded into a full send)
#   - Full send only when no candidate exists remotely
#   - SSH keepalive options are set, so a stalled remote host cannot hang the
#     run until systemd's TimeoutStartSec fires
#   - --dry-run transfers nothing
#   - Local snapshots beyond KEEP_LOCAL are pruned
#   - Missing BTRFS_BACKUP_HOST / BTRFS_BACKUP_DIR refuse to run
#
# The script runs as root against btrfs and ssh, so `btrfs`, `ssh` and `id` are
# stubbed on PATH. The stub `ssh` drains stdin exactly like the real one does
# (unless -n is passed), which is what makes the regression reproducible here.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/sys/sys-btrfs-backup"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    BACKUP_DIR="$TEST_DIR/backups"
    SOURCE_DIR="$TEST_DIR/source"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR" "$BACKUP_DIR" "$SOURCE_DIR"
    : > "$CALL_LOG"

    # id: the script refuses to run unless uid is 0
    cat > "$STUB_DIR/id" <<'STUB'
#!/usr/bin/env bash
echo 0
STUB

    # btrfs: records every call, emulates snapshot/send/delete
    cat > "$STUB_DIR/btrfs" <<'STUB'
#!/usr/bin/env bash
echo "btrfs $*" >> "$CALL_LOG"
case "$1 $2" in
    "subvolume show")   [ -d "$3" ] ;;
    "subvolume create") mkdir -p "$3" ;;
    "subvolume snapshot")
        # btrfs subvolume snapshot -r <src> <dst>
        mkdir -p "${@: -1}" ;;
    "subvolume delete")  rm -rf "$3" ;;
    "send"*|"send")      echo "fake-stream" ;;
    *) : ;;
esac
STUB

    # ssh: drains stdin like the real client (unless -n), records the remote
    # command, and succeeds only for the snapshot named in FAKE_REMOTE_HAS
    cat > "$STUB_DIR/ssh" <<'STUB'
#!/usr/bin/env bash
reads_stdin=1
for arg in "$@"; do
    [ "$arg" = "-n" ] && reads_stdin=0
done
[ "$reads_stdin" -eq 1 ] && cat > /dev/null

remote_cmd="${*: -1}"
echo "ssh $*" >> "$CALL_LOG"

case "$remote_cmd" in
    *"btrfs receive"*) exit 0 ;;
    *"subvolume show"*)
        [ -n "${FAKE_REMOTE_HAS:-}" ] && [[ "$remote_cmd" == *"$FAKE_REMOTE_HAS"* ]]
        ;;
    *) exit 0 ;;
esac
STUB

    chmod +x "$STUB_DIR"/*
}

teardown() {
    temp_del "$TEST_DIR"
}

# Runs the script with a scrubbed environment. `env -i` is required: BASH_ENV
# points at ~/.bashrc here, which re-prepends PATH and would shadow the stubs.
run_backup() {
    run env -i \
        HOME="$HOME" \
        PATH="$STUB_DIR:/usr/bin:/bin" \
        CALL_LOG="$CALL_LOG" \
        FAKE_REMOTE_HAS="${FAKE_REMOTE_HAS:-}" \
        BTRFS_BACKUP_SOURCE="$SOURCE_DIR" \
        BTRFS_BACKUP_LOCAL_DIR="$BACKUP_DIR" \
        BTRFS_BACKUP_HOST="backup@example.com" \
        BTRFS_BACKUP_DIR="/srv/example/backups" \
        BTRFS_BACKUP_SSH_KEY="/nonexistent-key" \
        BTRFS_BACKUP_KEEP_LOCAL="${BTRFS_BACKUP_KEEP_LOCAL:-3}" \
        BTRFS_BACKUP_KEEP_REMOTE="${BTRFS_BACKUP_KEEP_REMOTE:-14}" \
        bash "$SCRIPT" "$@"
}

seed_snapshots() {
    for name in "$@"; do
        mkdir -p "$BACKUP_DIR/$name"
    done
}

# ---------------------------------------------------------------------------
# Required configuration
# ---------------------------------------------------------------------------

@test "refuses to run without BTRFS_BACKUP_HOST" {
    run env -i HOME="$HOME" PATH="$STUB_DIR:/usr/bin:/bin" CALL_LOG="$CALL_LOG" \
        BTRFS_BACKUP_DIR="/srv/example/backups" bash "$SCRIPT" --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"BTRFS_BACKUP_HOST"* ]]
    [ ! -s "$CALL_LOG" ]
}

@test "refuses to run without BTRFS_BACKUP_DIR" {
    run env -i HOME="$HOME" PATH="$STUB_DIR:/usr/bin:/bin" CALL_LOG="$CALL_LOG" \
        BTRFS_BACKUP_HOST="backup@example.com" bash "$SCRIPT" --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"BTRFS_BACKUP_DIR"* ]]
    [ ! -s "$CALL_LOG" ]
}

@test "the script carries no default host or remote path" {
    run grep -nE '100\.[0-9]+\.[0-9]+\.[0-9]+|@[0-9]|/DATA/' "$SCRIPT"
    [ "$status" -ne 0 ]
    # Build needles at runtime so this file does not contain the forbidden words.
    forbidden="$(printf '%s|%s|%s|%s' 'nando''moreira' 'home''lab' 'Tail''scale' 'tail''scale')"
    run grep -nE "$forbidden" "$SCRIPT"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Incremental parent selection
# ---------------------------------------------------------------------------

@test "probes every local snapshot until it finds the parent on the remote host" {
    seed_snapshots os_20260101T000000 os_20260102T000000 os_20260103T000000
    export FAKE_REMOTE_HAS="os_20260101T000000"

    run_backup
    assert_success

    # The oldest is the only one present remotely: all three must be probed
    assert_equal "$(grep -c "subvolume show '/srv/example/backups/os_2026010" "$CALL_LOG")" "3"
}

@test "sends incremental with -p when a common parent exists" {
    seed_snapshots os_20260101T000000 os_20260102T000000
    export FAKE_REMOTE_HAS="os_20260101T000000"

    run_backup
    assert_success
    assert_output --partial "incremental send"
    grep -q "btrfs send -p $BACKUP_DIR/os_20260101T000000" "$CALL_LOG"
}

@test "does a full send when no candidate exists on the remote" {
    seed_snapshots os_20260101T000000 os_20260102T000000
    export FAKE_REMOTE_HAS="os_does-not-exist"

    run_backup
    assert_success
    assert_output --partial "full send"
    refute grep -q "btrfs send -p" "$CALL_LOG"
}

# ---------------------------------------------------------------------------
# SSH robustness
# ---------------------------------------------------------------------------

@test "uses ssh keepalive so a stalled remote cannot hang until systemd timeout" {
    seed_snapshots os_20260101T000000
    export FAKE_REMOTE_HAS="os_20260101T000000"

    run_backup
    assert_success
    grep -q "ServerAliveInterval" "$CALL_LOG"
    grep -q "ServerAliveCountMax" "$CALL_LOG"
}

# ---------------------------------------------------------------------------
# Dry run and pruning
# ---------------------------------------------------------------------------

@test "--dry-run neither sends nor deletes anything" {
    seed_snapshots os_20260101T000000 os_20260102T000000
    export FAKE_REMOTE_HAS="os_20260101T000000"

    run_backup --dry-run
    assert_success
    assert_output --partial "[dry-run]"
    refute grep -q "btrfs send" "$CALL_LOG"
    refute grep -q "subvolume delete" "$CALL_LOG"
}

@test "prunes local snapshots beyond KEEP_LOCAL" {
    seed_snapshots os_20260101T000000 os_20260102T000000 os_20260103T000000
    export FAKE_REMOTE_HAS="os_20260103T000000"
    export BTRFS_BACKUP_KEEP_LOCAL=2

    run_backup
    assert_success
    assert_output --partial "pruned local"
    grep -q "subvolume delete $BACKUP_DIR/os_20260101T000000" "$CALL_LOG"
}

@test "--help prints usage and exits 0" {
    run bash "$SCRIPT" --help
    assert_success
    assert_output --partial "sys-btrfs-backup"
}
