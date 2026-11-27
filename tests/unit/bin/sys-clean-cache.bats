#!/usr/bin/env bats

# Unit tests for bin/sys/sys-clean-cache
#
# Run:
#   ./tests/run-tests unit/bin/sys-clean-cache.bats
#
# Coverage:
#   - Every step prints the exact command before asking; "y" and an empty
#     answer run it, "s", "q" and EOF never do
#   - sudo is authenticated once upfront, only when a root step is selected
#   - Empty or missing targets are skipped without a prompt
#   - --dry-run and --only
#   - Targets that must survive: poetry virtualenvs, paru's packages.aur,
#     "target" dirs that are not Cargo build dirs
#   - A failing step does not abort the remaining ones
#
# System tools (sudo, paccache, pacman, docker, journalctl, systemd-tmpfiles)
# are stubbed on PATH and log every call to CALL_LOG.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/sys/sys-clean-cache"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    FAKE_HOME="$TEST_DIR/home"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR" "$FAKE_HOME/.cache" "$FAKE_HOME/hub" "$TEST_DIR/coredump"
    : > "$CALL_LOG"

    # sudo: log and run the command unprivileged. -v (upfront auth) is
    # logged and fails when FAKE_SUDO_AUTH=fail; -n true (keepalive) is silent.
    cat > "$STUB_DIR/sudo" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    -v) echo "sudo -v" >> "$CALL_LOG"; [ "${FAKE_SUDO_AUTH:-ok}" = "ok" ]; exit ;;
    -n) exit 0 ;;
esac
echo "sudo $*" >> "$CALL_LOG"
exec "$@"
STUB

    # paccache: dry runs report FAKE_PACCACHE ("none" means no candidates)
    cat > "$STUB_DIR/paccache" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    -d*)
        if [ "${FAKE_PACCACHE:-none}" = "none" ]; then
            echo "==> no candidate packages found for pruning"
        else
            echo "==> finished dry run: 10 candidates (disk space saved: ${FAKE_PACCACHE})"
        fi ;;
    *) echo "paccache $*" >> "$CALL_LOG"; exit "${FAKE_PACCACHE_EXIT:-0}" ;;
esac
STUB

    # pacman: -Qdtq lists FAKE_ORPHANS, everything else is logged
    cat > "$STUB_DIR/pacman" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "-Qdtq" ]; then
    for p in ${FAKE_ORPHANS:-}; do echo "$p"; done
    exit 0
fi
echo "pacman $*" >> "$CALL_LOG"
STUB

    # docker: daemon reachable only when FAKE_DOCKER=up
    cat > "$STUB_DIR/docker" <<'STUB'
#!/usr/bin/env bash
[ "${FAKE_DOCKER:-down}" = "up" ] || exit 1
case "$1" in
    info) exit 0 ;;
    system)
        if [ "$2" = "df" ]; then echo "9.4GB (63%)"; exit 0; fi ;;
esac
echo "docker $*" >> "$CALL_LOG"
STUB

    cat > "$STUB_DIR/journalctl" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "--disk-usage" ]; then
    echo "Archived and active journals take up 45.5M in the file system."
    exit 0
fi
echo "journalctl $*" >> "$CALL_LOG"
STUB

    cat > "$STUB_DIR/systemd-tmpfiles" <<'STUB'
#!/usr/bin/env bash
echo "systemd-tmpfiles $*" >> "$CALL_LOG"
STUB

    chmod +x "$STUB_DIR"/*
}

teardown() {
    temp_del "$TEST_DIR"
}

# env -i: BASH_ENV re-prepends PATH and would shadow the stubs.
# Answers for the prompts are fed on stdin through $ANSWERS.
run_clean() {
    run env -i \
        HOME="$FAKE_HOME" \
        PATH="$STUB_DIR:/usr/bin:/bin" \
        TERM=dumb \
        CALL_LOG="$CALL_LOG" \
        FAKE_PACCACHE="${FAKE_PACCACHE:-none}" \
        FAKE_PACCACHE_EXIT="${FAKE_PACCACHE_EXIT:-0}" \
        FAKE_ORPHANS="${FAKE_ORPHANS:-}" \
        FAKE_DOCKER="${FAKE_DOCKER:-down}" \
        FAKE_SUDO_AUTH="${FAKE_SUDO_AUTH:-ok}" \
        SYS_CLEAN_DEV_DIR="$FAKE_HOME/hub" \
        SYS_CLEAN_COREDUMP_DIR="$TEST_DIR/coredump" \
        bash "$SCRIPT" "$@" <<< "${ANSWERS:-}"
}

seed_file() {
    mkdir -p "$(dirname "$1")"
    head -c 4096 /dev/zero > "$1"
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

@test "--help prints usage and exits 0" {
    run_clean --help
    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "--only"
}

@test "unknown option exits with an error" {
    run_clean --bogus
    assert_failure
}

@test "--only with an unknown step exits with an error" {
    run_clean --only nope
    assert_failure
    assert_output --partial "unknown step: nope"
}

@test "--list shows the available steps" {
    run_clean --list
    assert_success
    assert_output --partial "pacman-old"
    assert_output --partial "thumbnails"
    assert_output --partial "coredumps"
}

# ---------------------------------------------------------------------------
# Prompt and execution
# ---------------------------------------------------------------------------

@test "prints the exact command before asking" {
    seed_file "$FAKE_HOME/.cache/thumbnails/large/a.png"
    ANSWERS="s" run_clean --only thumbnails
    assert_success
    assert_output --partial "find $FAKE_HOME/.cache/thumbnails -mindepth 1 -delete"
}

@test "y runs: clears contents and keeps the directory" {
    seed_file "$FAKE_HOME/.cache/thumbnails/large/a.png"
    ANSWERS="y" run_clean --only thumbnails
    assert_success
    assert_dir_exists "$FAKE_HOME/.cache/thumbnails"
    assert_file_not_exists "$FAKE_HOME/.cache/thumbnails/large/a.png"
}

@test "s skips the step and keeps the files" {
    seed_file "$FAKE_HOME/.cache/thumbnails/large/a.png"
    ANSWERS="s" run_clean --only thumbnails
    assert_success
    assert_file_exists "$FAKE_HOME/.cache/thumbnails/large/a.png"
}

@test "empty answer means yes" {
    seed_file "$FAKE_HOME/.cache/thumbnails/large/a.png"
    ANSWERS="" run_clean --only thumbnails
    assert_success
    assert_output --partial "default: yes"
    assert_file_not_exists "$FAKE_HOME/.cache/thumbnails/large/a.png"
}

@test "unknown answer skips the step" {
    seed_file "$FAKE_HOME/.cache/thumbnails/a.png"
    ANSWERS="talvez" run_clean --only thumbnails
    assert_success
    assert_output --regexp "skipped +thumbnails"
    assert_file_exists "$FAKE_HOME/.cache/thumbnails/a.png"
}

@test "q quits and does not run later steps" {
    seed_file "$FAKE_HOME/.cache/thumbnails/a.png"
    seed_file "$FAKE_HOME/.local/share/Trash/files/old.txt"
    ANSWERS="q" run_clean --only thumbnails,trash
    assert_success
    assert_file_exists "$FAKE_HOME/.cache/thumbnails/a.png"
    assert_file_exists "$FAKE_HOME/.local/share/Trash/files/old.txt"
    refute_output --partial "Trash -mindepth"
}

@test "EOF on stdin quits without running anything" {
    seed_file "$FAKE_HOME/.cache/thumbnails/a.png"
    run env -i HOME="$FAKE_HOME" PATH="$STUB_DIR:/usr/bin:/bin" TERM=dumb \
        CALL_LOG="$CALL_LOG" SYS_CLEAN_DEV_DIR="$FAKE_HOME/hub" \
        bash "$SCRIPT" --only thumbnails < /dev/null
    assert_success
    assert_file_exists "$FAKE_HOME/.cache/thumbnails/a.png"
}

@test "empty or missing directory is skipped without asking" {
    mkdir -p "$FAKE_HOME/.cache/thumbnails"
    ANSWERS="y" run_clean --only thumbnails,spotify
    assert_success
    assert_output --partial "nothing to clean"
    refute_output --partial "[y]es"
}

@test "--dry-run neither asks nor runs" {
    seed_file "$FAKE_HOME/.cache/thumbnails/a.png"
    FAKE_PACCACHE="1.5 GiB" ANSWERS="y" run_clean --dry-run --only thumbnails,pacman-old
    assert_success
    assert_output --partial "find $FAKE_HOME/.cache/thumbnails -mindepth 1 -delete"
    assert_output --partial "sudo paccache -rk2"
    refute_output --partial "[y]es"
    assert_file_exists "$FAKE_HOME/.cache/thumbnails/a.png"
    run cat "$CALL_LOG"
    assert_output ""
}

@test "a failing step does not abort later ones" {
    seed_file "$FAKE_HOME/.local/share/Trash/files/old.txt"
    FAKE_PACCACHE="1.5 GiB" FAKE_PACCACHE_EXIT=1 ANSWERS=$'y\ny' \
        run_clean --only pacman-old,trash
    assert_success
    assert_output --partial "failed"
    assert_file_not_exists "$FAKE_HOME/.local/share/Trash/files/old.txt"
}

@test "summary lists executed and skipped steps" {
    seed_file "$FAKE_HOME/.cache/thumbnails/a.png"
    seed_file "$FAKE_HOME/.local/share/Trash/files/old.txt"
    ANSWERS=$'y\ns' run_clean --only thumbnails,trash
    assert_success
    assert_output --regexp "done +thumbnails"
    assert_output --regexp "skipped +trash"
}

# ---------------------------------------------------------------------------
# Upfront sudo
# ---------------------------------------------------------------------------

@test "asks for sudo once at the start, before the first step" {
    FAKE_PACCACHE="1.5 GiB" ANSWERS=$'y\ny' run_clean --only pacman-old,journal
    assert_success
    run cat "$CALL_LOG"
    assert_line --index 0 "sudo -v"
    run grep -c "^sudo -v$" "$CALL_LOG"
    assert_output "1"
}

@test "does not ask for sudo when no selected step needs root" {
    seed_file "$FAKE_HOME/.cache/thumbnails/a.png"
    ANSWERS="y" run_clean --only thumbnails
    assert_success
    run cat "$CALL_LOG"
    refute_output --partial "sudo -v"
}

@test "does not ask for sudo on --dry-run" {
    run_clean --dry-run --only journal
    assert_success
    run cat "$CALL_LOG"
    refute_output --partial "sudo -v"
}

@test "exits with an error if sudo authentication fails" {
    FAKE_SUDO_AUTH=fail ANSWERS="y" run_clean --only journal
    assert_failure
    assert_output --partial "sudo authentication failed"
    run cat "$CALL_LOG"
    refute_output --partial "journalctl"
}

# ---------------------------------------------------------------------------
# Targets that must survive
# ---------------------------------------------------------------------------

@test "poetry: clears cache and artifacts, keeps virtualenvs" {
    seed_file "$FAKE_HOME/.cache/pypoetry/cache/x.whl"
    seed_file "$FAKE_HOME/.cache/pypoetry/artifacts/y.whl"
    seed_file "$FAKE_HOME/.cache/pypoetry/virtualenvs/proj/bin/python"
    ANSWERS="y" run_clean --only poetry
    assert_success
    assert_file_not_exists "$FAKE_HOME/.cache/pypoetry/cache/x.whl"
    assert_file_not_exists "$FAKE_HOME/.cache/pypoetry/artifacts/y.whl"
    assert_file_exists "$FAKE_HOME/.cache/pypoetry/virtualenvs/proj/bin/python"
}

@test "aur: clears paru clones and keeps packages.aur" {
    seed_file "$FAKE_HOME/.cache/paru/clone/foo/foo.pkg.tar.zst"
    seed_file "$FAKE_HOME/.cache/paru/packages.aur"
    ANSWERS="y" run_clean --only aur
    assert_success
    assert_file_not_exists "$FAKE_HOME/.cache/paru/clone/foo/foo.pkg.tar.zst"
    assert_file_exists "$FAKE_HOME/.cache/paru/packages.aur"
}

@test "rust-targets: removes only target/ next to a Cargo.toml" {
    seed_file "$FAKE_HOME/hub/app/Cargo.toml"
    seed_file "$FAKE_HOME/hub/app/target/debug/app"
    seed_file "$FAKE_HOME/hub/web/target/keep.txt"
    ANSWERS="y" run_clean --only rust-targets
    assert_success
    assert_output --partial "$FAKE_HOME/hub/app/target"
    assert_dir_not_exists "$FAKE_HOME/hub/app/target"
    assert_file_exists "$FAKE_HOME/hub/web/target/keep.txt"
}

# ---------------------------------------------------------------------------
# System steps
# ---------------------------------------------------------------------------

@test "pacman-old: runs paccache -rk2 via sudo when candidates exist" {
    FAKE_PACCACHE="34.87 GiB" ANSWERS="y" run_clean --only pacman-old
    assert_success
    assert_output --partial "34.87 GiB"
    run cat "$CALL_LOG"
    assert_line "sudo paccache -rk2"
}

@test "pacman-old: skips without asking when there are no candidates" {
    ANSWERS="y" run_clean --only pacman-old
    assert_success
    assert_output --partial "nothing to clean"
    run cat "$CALL_LOG"
    refute_output --partial "paccache"
}

@test "orphans: removes the orphan list with pacman -Rns" {
    FAKE_ORPHANS="electron39 llvm21-libs" ANSWERS="y" run_clean --only orphans
    assert_success
    assert_output --partial "sudo pacman -Rns electron39 llvm21-libs"
    run cat "$CALL_LOG"
    assert_line "pacman -Rns electron39 llvm21-libs"
}

@test "orphans: skips when there are no orphans" {
    ANSWERS="y" run_clean --only orphans
    assert_success
    assert_output --partial "nothing to clean"
}

@test "docker: skips when the daemon does not answer" {
    ANSWERS="y" run_clean --only docker
    assert_success
    assert_output --partial "docker daemon not reachable"
    run cat "$CALL_LOG"
    assert_output ""
}

@test "docker: runs system prune -a -f when confirmed" {
    FAKE_DOCKER=up ANSWERS="y" run_clean --only docker
    assert_success
    run cat "$CALL_LOG"
    assert_line "docker system prune -a -f"
}

@test "journal and tmp run via sudo" {
    ANSWERS=$'y\ny' run_clean --only tmp,journal
    assert_success
    run cat "$CALL_LOG"
    assert_line "sudo systemd-tmpfiles --clean"
    assert_line "sudo journalctl --vacuum-time=2weeks"
}

@test "coredumps: deletes the coredumps directory contents" {
    seed_file "$TEST_DIR/coredump/core.x.zst"
    ANSWERS="y" run_clean --only coredumps
    assert_success
    assert_file_not_exists "$TEST_DIR/coredump/core.x.zst"
    run cat "$CALL_LOG"
    assert_line --partial "sudo find $TEST_DIR/coredump -mindepth 1 -delete"
}
