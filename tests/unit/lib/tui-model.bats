#!/usr/bin/env bats

# Unit tests for lib/tui-model.sh: the screen-free logic behind `dotfiles tui`.
# The prerequisites gate (base tools and pending updates) must pass before the
# install checklist runs; each checklist step is one `dotfiles` command.

load '../../bats/helpers/setup'

setup() {
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS"
    : > "$LOG"
    # Every base tool present by default; tests delete a stub to make it missing.
    for t in git curl sudo yay; do
        printf '#!/bin/sh\nexit 0\n' > "$STUBS/$t"
    done
    # pacman -Q answers for base-devel unless FAKE_NO_BASE_DEVEL is set.
    cat > "$STUBS/pacman" <<'STUB'
#!/bin/sh
[ "$1" = "-Q" ] && [ "$2" = "base-devel" ] && [ -n "${FAKE_NO_BASE_DEVEL:-}" ] && exit 1
exit 0
STUB
    # checkupdates: FAKE_UPDATES lines, exit 2 when none, FAKE_CHECK_FAIL -> exit 1.
    cat > "$STUBS/checkupdates" <<'STUB'
#!/bin/sh
[ -n "${FAKE_CHECK_FAIL:-}" ] && exit 1
[ -z "${FAKE_UPDATES:-}" ] && exit 2
printf '%s\n' $FAKE_UPDATES
STUB
    # A fake dotfiles CLI that records its arguments and fails on demand.
    cat > "$STUBS/dotfiles" <<'STUB'
#!/bin/sh
echo "dotfiles $*" >> "$CALL_LOG"
case " $* " in *" ${FAKE_FAIL_ARG:-__none__} "*) exit 1 ;; esac
exit 0
STUB
    chmod +x "$STUBS"/*
}

# model <code>: run code with lib/tui-model.sh sourced and only the stubs on PATH.
model() {
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="$STUBS" CALL_LOG="$LOG" \
        FAKE_NO_BASE_DEVEL="${FAKE_NO_BASE_DEVEL:-}" FAKE_UPDATES="${FAKE_UPDATES:-}" \
        FAKE_CHECK_FAIL="${FAKE_CHECK_FAIL:-}" FAKE_FAIL_ARG="${FAKE_FAIL_ARG:-}" \
        DOTFILES_TUI_CLI="$STUBS/dotfiles" \
        /usr/bin/bash -c "source '$PROJECT_ROOT/lib/tui-model.sh'; $1"
}

# ---- prerequisites ----

@test "nothing is missing when every base tool is installed" {
    model '_tui_base_missing'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "missing tools and packages are listed one per line" {
    rm "$STUBS/curl"
    FAKE_NO_BASE_DEVEL=1 model '_tui_base_missing'
    [ "$output" = "curl
base-devel" ]
}

@test "paru counts as the AUR helper and none at all is reported" {
    rm "$STUBS/yay"
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/paru"; chmod +x "$STUBS/paru"
    model '_tui_base_missing'
    [ -z "$output" ]
    rm "$STUBS/paru"
    model '_tui_base_missing'
    [ "$output" = "aur-helper" ]
}

@test "pending updates are counted" {
    FAKE_UPDATES="linux mesa zsh" model '_tui_pending_updates'
    [ "$status" -eq 0 ]
    [ "$output" = "3" ]
}

@test "an up to date system has zero pending updates" {
    model '_tui_pending_updates'
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

@test "a failed update check is reported as an error, not as up to date" {
    FAKE_CHECK_FAIL=1 model '_tui_pending_updates'
    [ "$status" -ne 0 ]
}

@test "the gate opens only with the base complete and no pending updates" {
    model '_tui_ready && echo READY'
    [ "$output" = "READY" ]
    FAKE_UPDATES="linux" model '_tui_ready || echo BLOCKED'
    [ "$output" = "BLOCKED" ]
    rm "$STUBS/git"
    model '_tui_ready || echo BLOCKED'
    [ "$output" = "BLOCKED" ]
    rm -f "$STUBS/git"; printf '#!/bin/sh\nexit 0\n' > "$STUBS/git"; chmod +x "$STUBS/git"
    FAKE_CHECK_FAIL=1 model '_tui_ready || echo BLOCKED'
    [ "$output" = "BLOCKED" ]
}

@test "missing base items map to the packages that install them" {
    model '_tui_base_packages git base-devel aur-helper'
    [ "$output" = "git base-devel" ]
}

# ---- checklist ----

@test "the checklist lists every install step with a label" {
    model '_tui_steps'
    for id in pacman aur flatpak node sh fonts langs links setup; do
        [[ "$output" == *"$id|"* ]] || { echo "missing step: $id"; false; }
    done
}

@test "each step maps to one dotfiles command" {
    model '_tui_step_args aur; _tui_step_args links; _tui_step_args setup'
    [ "${lines[0]}" = "packages install --manager aur --yes" ]
    [ "${lines[1]}" = "links create" ]
    [ "${lines[2]}" = "setup --yes" ]
}

@test "an unknown step is rejected" {
    model '_tui_step_args nope'
    [ "$status" -ne 0 ]
}

@test "selected steps run in order and failures are collected" {
    FAKE_FAIL_ARG=aur model '_tui_run_steps pacman aur links; echo "RC=$?"; echo "FAILED=${TUI_FAILED_STEPS[*]}"'
    run cat "$LOG"
    [ "${lines[0]}" = "dotfiles packages install --manager pacman --yes" ]
    [ "${lines[1]}" = "dotfiles packages install --manager aur --yes" ]
    [ "${lines[2]}" = "dotfiles links create" ]
    FAKE_FAIL_ARG=aur model '_tui_run_steps pacman aur links; echo "RC=$?"; echo "FAILED=${TUI_FAILED_STEPS[*]}"'
    [[ "$output" == *"RC=1"* ]]
    [[ "$output" == *"FAILED=aur"* ]]
}

@test "the model parses under the strict options tuish turns on" {
    model 'set -euf; _tui_steps >/dev/null; _tui_base_missing >/dev/null; echo OK'
    [[ "$output" == *"OK"* ]]
}

# ---- background runner ----

@test "the logged runner records each step and captures its output" {
    cat > "$STUBS/dotfiles" <<'STUB'
#!/bin/sh
echo "dotfiles $*" >> "$CALL_LOG"
printf '\033[32minstalling\033[0m %s\n' "$*"
case " $* " in *" ${FAKE_FAIL_ARG:-__none__} "*) echo "boom" >&2; exit 3 ;; esac
STUB
    chmod +x "$STUBS/dotfiles"
    FAKE_FAIL_ARG=aur model "_tui_run_logged '$BATS_TEST_TMPDIR/state' '$BATS_TEST_TMPDIR/log' pacman aur links"
    run cat "$BATS_TEST_TMPDIR/state"
    [ "$output" = "start pacman
ok pacman
start aur
fail aur
start links
ok links
done 1" ]
    grep -q 'installing.* packages install --manager pacman --yes' "$BATS_TEST_TMPDIR/log"
    grep -q 'boom' "$BATS_TEST_TMPDIR/log"
    grep -q '^==> aur' "$BATS_TEST_TMPDIR/log"
}

@test "the logged runner never reads the terminal" {
    cat > "$STUBS/dotfiles" <<'STUB'
#!/bin/sh
read -r answer && echo "read: $answer"
echo "stdin done"
STUB
    chmod +x "$STUBS/dotfiles"
    run bash -c "echo SECRET | env -i HOME='$BATS_TEST_TMPDIR' PATH='$STUBS' DOTFILES_TUI_CLI='$STUBS/dotfiles' /usr/bin/bash -c \"source '$PROJECT_ROOT/lib/tui-model.sh'; _tui_run_logged '$BATS_TEST_TMPDIR/state' '$BATS_TEST_TMPDIR/log' links\""
    run grep -c SECRET "$BATS_TEST_TMPDIR/log"
    [ "$output" = "0" ]
}

@test "a raw command can run as one logged step" {
    model "_tui_run_logged_cmd '$BATS_TEST_TMPDIR/state' '$BATS_TEST_TMPDIR/log' update '$STUBS/dotfiles' custom args"
    run cat "$BATS_TEST_TMPDIR/state"
    [ "$output" = "start update
ok update
done 0" ]
}

@test "step status follows the state file" {
    printf 'start pacman\nok pacman\nstart aur\nfail aur\nstart links\n' > "$BATS_TEST_TMPDIR/state"
    model "for s in pacman aur links fonts; do _tui_step_status '$BATS_TEST_TMPDIR/state' \$s; done; _tui_runner_done '$BATS_TEST_TMPDIR/state' || echo running"
    [ "$output" = "ok
failed
running
pending
running" ]
    printf 'done 1\n' >> "$BATS_TEST_TMPDIR/state"
    model "_tui_runner_done '$BATS_TEST_TMPDIR/state' && echo finished"
    [ "$output" = "finished" ]
}

@test "the log tail drops color codes and cuts long lines" {
    printf 'one\n\033[1;32mtwo\033[0m\n%s\n' "$(printf 'x%.0s' $(seq 1 50))" > "$BATS_TEST_TMPDIR/log"
    PATH_EXTRA=1 run env -i PATH="/usr/bin:/bin" /usr/bin/bash -c "source '$PROJECT_ROOT/lib/tui-model.sh'; _tui_log_tail '$BATS_TEST_TMPDIR/log' 2 10"
    [ "$output" = "two
xxxxxxxxxx" ]
}
