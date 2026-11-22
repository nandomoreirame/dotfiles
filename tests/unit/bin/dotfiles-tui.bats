#!/usr/bin/env bats

# Unit tests for bin/utils/dotfiles-tui (`dotfiles tui`). The TUI is driven
# through a pseudo-terminal (util-linux script) with keys piped in; the dotfiles
# CLI it calls is a stub that logs its arguments.

load '../../bats/helpers/setup'
bats_require_minimum_version 1.5.0

SCRIPT="$PROJECT_ROOT/bin/utils/dotfiles-tui"

setup() {
    STUBS="$BATS_TEST_TMPDIR/stubs"
    export CALL_LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS"
    : > "$CALL_LOG"
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/yay"
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/pacman"
    cat > "$STUBS/checkupdates" <<'STUB'
#!/bin/sh
[ -z "${FAKE_UPDATES:-}" ] && exit 2
printf '%s\n' $FAKE_UPDATES
STUB
    cat > "$STUBS/dotfiles" <<'STUB'
#!/bin/sh
echo "dotfiles $*" >> "$CALL_LOG"
echo "stub output for $*"
case " $* " in *" ${FAKE_FAIL_ARG:-__none__} "*) exit 1 ;; esac
exit 0
STUB
    # sudo -v / sudo -n true succeed without a password in the tests.
    printf '#!/bin/sh\necho "sudo $*" >> "$CALL_LOG.sudo"\nexit 0\n' > "$STUBS/sudo"
    chmod +x "$STUBS"/*
}

# drive <key>...: run the TUI in a sized pty and feed one key (printf escape)
# per second. Keys typed while a screen restarts are dropped, as in real use.
drive() {
    command -v script >/dev/null || skip "script (util-linux) not installed"
    local feed="sleep 2" key
    for key in "$@"; do feed="$feed; printf '$key'; sleep 1"; done
    run timeout 40 env -i HOME="$BATS_TEST_TMPDIR" TERM=xterm-256color \
        PATH="$STUBS:/usr/bin:/bin" CALL_LOG="$CALL_LOG" FAKE_UPDATES="${FAKE_UPDATES:-}" \
        FAKE_FAIL_ARG="${FAKE_FAIL_ARG:-}" \
        DOTFILES_TUI_CLI="$STUBS/dotfiles" \
        bash -c "($feed) | script -qec 'stty rows 30 cols 100; $SCRIPT' /dev/null"
}

@test "--help prints the usage without a terminal" {
    run "$SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: dotfiles tui"* ]]
}

@test "without a terminal it refuses and points to dotfiles install" {
    run --separate-stderr "$SCRIPT" </dev/null
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"needs a terminal"* ]]
    [[ "$stderr" == *"dotfiles install"* ]]
}

@test "the prerequisites screen lists the base and the update state, q quits" {
    drive 'q'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Prerequisites"* ]]
    [[ "$output" == *"git"* ]]
    [[ "$output" == *"base-devel"* ]]
    [[ "$output" == *"up to date"* ]]
}

@test "pending updates keep the checklist locked" {
    FAKE_UPDATES="linux mesa" drive '\r' 'q'
    [ "$status" -eq 0 ]
    [[ "$output" == *"2 pending updates"* ]]
    [[ "$output" != *"Install checklist"* ]]
}

@test "with the gate open, enter shows the checklist and runs only the selected steps" {
    drive '\r' ' ' '\r' '\r' 'q'
    [[ "$output" == *"Install checklist"* ]]
    run cat "$CALL_LOG"
    [ "$output" = "dotfiles packages install --manager pacman --yes" ]
}

@test "the install output and the result show inside the TUI" {
    drive '\r' ' ' '\r' '\r' 'q'
    [[ "$output" == *"Installing"* ]]
    [[ "$output" == *"stub output for packages install --manager pacman --yes"* ]]
    [[ "$output" == *"All steps finished"* ]]
    [[ "$output" == *".cache/dotfiles/tui-"*".log"* ]]
    # The commands ran in the background, never in the normal terminal.
    [[ "$output" != *"==> pacman"*"Press enter to return"* ]]
}

@test "a failed step is marked and named in the summary" {
    FAKE_FAIL_ARG=pacman drive '\r' ' ' '\r' '\r' 'q'
    [[ "$output" == *"Failed: pacman"* ]]
}

@test "sudo is unlocked once before the background run" {
    drive '\r' ' ' '\r' '\r' 'q'
    grep -q '^sudo -v$' "$CALL_LOG.sudo"
}

@test "nothing runs when no step is selected" {
    drive '\r' '\r' 'q'
    [ ! -s "$CALL_LOG" ]
}

@test "dotfiles tui is wired into the CLI and its help" {
    run env -i HOME="$BATS_TEST_TMPDIR" PATH=/usr/bin:/bin TERM=xterm-256color bash "$PROJECT_ROOT/bin/dotfiles" tui --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: dotfiles tui"* ]]
    run env -i HOME="$BATS_TEST_TMPDIR" PATH=/usr/bin:/bin TERM=xterm-256color bash "$PROJECT_ROOT/bin/dotfiles" --help
    [[ "$output" == *"tui"* ]]
}
