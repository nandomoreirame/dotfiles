#!/usr/bin/env bats

# Unit tests for bin/utils/nocta (REQ-005 IPC compatibility layer)
#
# Run:
#   ./tests/run-tests tests/unit/bin/nocta.bats
#
# Detects the running shell via stubbed `pgrep -x noctalia` (a stray `qs`
# must be ignored) and records every noctalia call. `env -i` is required: BASH_ENV
# re-prepends PATH and would shadow the stubs.

load '../../bats/helpers/setup'
bats_require_minimum_version 1.5.0

SCRIPT="$PROJECT_ROOT/bin/utils/nocta"

setup() {
    export NOCTALIA_PLUGIN_AUTHOR="${NOCTALIA_PLUGIN_AUTHOR:-jane}"
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"

    mkdir -p "$STUB_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/pgrep" <<'STUB'
#!/usr/bin/env bash
# Answer pgrep -x qs|noctalia from FAKE_*_PIDS (space-separated).
if [ "$1" = "-x" ]; then
    case "$2" in
    qs)
        if [ -n "${FAKE_QS_PIDS:-}" ]; then
            # shellcheck disable=SC2086
            printf '%s\n' $FAKE_QS_PIDS
            exit 0
        fi
        exit 1
        ;;
    noctalia)
        if [ -n "${FAKE_NOCTALIA_PIDS:-}" ]; then
            # shellcheck disable=SC2086
            printf '%s\n' $FAKE_NOCTALIA_PIDS
            exit 0
        fi
        exit 1
        ;;
    esac
fi
exit 1
STUB

    cat > "$STUB_DIR/noctalia" <<'STUB'
#!/usr/bin/env bash
if [ "$#" -eq 0 ]; then
    echo "noctalia" >> "$CALL_LOG"
else
    echo "noctalia $*" >> "$CALL_LOG"
fi
# v5 dnd status
if [ "$1" = "msg" ] && [ "$2" = "notification-dnd-status" ]; then
    printf '%s\n' "${FAKE_DND_STATUS:-off}"
fi
exit 0
STUB

    chmod +x "$STUB_DIR"/*
}

teardown() {
    temp_del "$TEST_DIR"
}

# Plugin tests need an author; built-in action tests leave behavior unchanged.
# Individual tests may override NOCTA_PLUGIN_ENTRIES / PANELS.

# Runs nocta with a scrubbed environment so stubs win on PATH.
# Pass --separate-stderr as the first arg to capture stderr in $stderr.
# NOCTA_PLUGIN_ENTRIES is forwarded only when set in the parent so the
# script default (empty NOCTA_PLUGIN_ENTRIES) applies when the test leaves it unset.
run_nocta() {
    local separate=()
    local env_extra=()
    if [ "${1:-}" = "--separate-stderr" ]; then
        separate=(--separate-stderr)
        shift
    fi
    if [ -n "${NOCTA_PLUGIN_ENTRIES+x}" ]; then
        env_extra+=(NOCTA_PLUGIN_ENTRIES="$NOCTA_PLUGIN_ENTRIES")
    fi
    if [ -n "${NOCTA_PLUGIN_PANELS+x}" ]; then
        env_extra+=(NOCTA_PLUGIN_PANELS="$NOCTA_PLUGIN_PANELS")
    fi
    if [ -n "${NOCTALIA_PLUGIN_AUTHOR+x}" ] && [ -n "${NOCTALIA_PLUGIN_AUTHOR}" ]; then
        env_extra+=(NOCTALIA_PLUGIN_AUTHOR="$NOCTALIA_PLUGIN_AUTHOR")
    fi
    run "${separate[@]}" env -i \
        HOME="$TEST_DIR" \
        PATH="$STUB_DIR:/usr/bin:/bin" \
        CALL_LOG="$CALL_LOG" \
        FAKE_QS_PIDS="${FAKE_QS_PIDS:-}" \
        FAKE_NOCTALIA_PIDS="${FAKE_NOCTALIA_PIDS:-}" \
        FAKE_DND_STATUS="${FAKE_DND_STATUS:-}" \
        "${env_extra[@]}" \
        bash "$SCRIPT" "$@"
}

# ---- detection / errors ----

@test "no shell running exits 3 with message on stderr" {
    run_nocta --separate-stderr launcher

    [ "$status" -eq 3 ]
    [[ "$stderr" == *"no"* ]] || [[ "$stderr" == *"shell"* ]] || [[ "$stderr" == *"running"* ]]
    [ ! -s "$CALL_LOG" ]
}

@test "unknown action exits 2" {
    FAKE_NOCTALIA_PIDS="2222"

    run_nocta --separate-stderr not-a-real-action

    [ "$status" -eq 2 ]
    [ ! -s "$CALL_LOG" ] || ! grep -qE '^(qs|noctalia) ' "$CALL_LOG"
}

@test "a lone qs process is not a Noctalia shell: exits 3" {
    FAKE_QS_PIDS="1111"

    run_nocta --separate-stderr launcher

    [ "$status" -eq 3 ]
    [ ! -s "$CALL_LOG" ]
}

@test "nocta has no v4 (qs) code path left" {
    ! grep -qE '\bqs\b|v4' "$SCRIPT"
}

# ---- v5 action table (REQ-005) ----

@test "v5 launcher -> noctalia msg panel-toggle launcher" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta launcher
    assert_success
    grep -qx "noctalia msg panel-toggle launcher" "$CALL_LOG"
}

@test "v5 clipboard -> noctalia msg panel-toggle clipboard" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta clipboard
    assert_success
    grep -qx "noctalia msg panel-toggle clipboard" "$CALL_LOG"
}

@test "v5 control-center -> noctalia msg panel-toggle control-center" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta control-center
    assert_success
    grep -qx "noctalia msg panel-toggle control-center" "$CALL_LOG"
}

@test "v5 settings -> noctalia msg settings-toggle" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta settings
    assert_success
    grep -qx "noctalia msg settings-toggle" "$CALL_LOG"
}

@test "v5 lock -> noctalia msg session lock" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta lock
    assert_success
    grep -qx "noctalia msg session lock" "$CALL_LOG"
}

@test "v5 volume-up -> noctalia msg volume-up" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta volume-up
    assert_success
    grep -qx "noctalia msg volume-up" "$CALL_LOG"
}

@test "v5 volume-down -> noctalia msg volume-down" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta volume-down
    assert_success
    grep -qx "noctalia msg volume-down" "$CALL_LOG"
}

@test "v5 volume-mute -> noctalia msg volume-mute" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta volume-mute
    assert_success
    grep -qx "noctalia msg volume-mute" "$CALL_LOG"
}

@test "v5 brightness-up -> noctalia msg brightness-up" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta brightness-up
    assert_success
    grep -qx "noctalia msg brightness-up" "$CALL_LOG"
}

@test "v5 brightness-down -> noctalia msg brightness-down" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta brightness-down
    assert_success
    grep -qx "noctalia msg brightness-down" "$CALL_LOG"
}

@test "v5 bar-toggle -> noctalia msg bar-toggle" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta bar-toggle
    assert_success
    grep -qx "noctalia msg bar-toggle" "$CALL_LOG"
}

@test "v5 widgets-edit -> noctalia msg desktop-widgets-toggle-edit" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta widgets-edit
    assert_success
    grep -qx "noctalia msg desktop-widgets-toggle-edit" "$CALL_LOG"
}

@test "v5 wallpaper-random -> noctalia msg wallpaper-random" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta wallpaper-random
    assert_success
    grep -qx "noctalia msg wallpaper-random" "$CALL_LOG"
}

@test "v5 media-pause -> noctalia msg media pause" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta media-pause
    assert_success
    grep -qx "noctalia msg media pause" "$CALL_LOG"
}

@test "v5 dnd on -> noctalia msg notification-dnd-set on" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta dnd on
    assert_success
    grep -qx "noctalia msg notification-dnd-set on" "$CALL_LOG"
}

@test "v5 dnd off -> noctalia msg notification-dnd-set off" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta dnd off
    assert_success
    grep -qx "noctalia msg notification-dnd-set off" "$CALL_LOG"
}

@test "v5 dnd status prints on" {
    FAKE_NOCTALIA_PIDS="2222"
    FAKE_DND_STATUS="on"

    run_nocta dnd status

    assert_success
    [ "$output" = "on" ]
    grep -qx "noctalia msg notification-dnd-status" "$CALL_LOG"
}

@test "v5 dnd status prints off" {
    FAKE_NOCTALIA_PIDS="2222"
    FAKE_DND_STATUS="off"

    run_nocta dnd status

    assert_success
    [ "$output" = "off" ]
}

@test "v5 awake on -> noctalia msg caffeine-enable" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta awake on
    assert_success
    grep -qx "noctalia msg caffeine-enable" "$CALL_LOG"
}

@test "v5 awake off -> noctalia msg caffeine-disable" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta awake off
    assert_success
    grep -qx "noctalia msg caffeine-disable" "$CALL_LOG"
}

# ---- plugin <name> <event> (Task 2) ----

@test "v5 plugin missing args exits 2" {
    FAKE_NOCTALIA_PIDS="2222"
    run_nocta --separate-stderr plugin daybar
    [ "$status" -eq 2 ]
    [ ! -s "$CALL_LOG" ]
}

@test "v5 plugin with entry -> noctalia msg plugin focused event" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES="daybar=widget gistbar=widget"

    run_nocta plugin daybar capture

    assert_success
    grep -qx "noctalia msg plugin jane/daybar:widget focused capture" "$CALL_LOG"
}

@test "v5 plugin missing entry exits 4" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES=""

    run_nocta --separate-stderr plugin gistbar create

    [ "$status" -eq 4 ]
    [[ "$stderr" == *"plugin gistbar not migrated to v5"* ]]
    [ ! -s "$CALL_LOG" ]
}

@test "v5 plugin panel -> noctalia msg panel-toggle without entry" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES=""

    run_nocta plugin gistbar panel

    assert_success
    grep -qx "noctalia msg panel-toggle jane/gistbar:panel" "$CALL_LOG"
}

@test "v5 plugin daybar panel -> panel-toggle the toolbar panel" {
    FAKE_NOCTALIA_PIDS="2222"
    unset NOCTA_PLUGIN_ENTRIES

    run_nocta plugin daybar panel

    assert_success
    grep -qx "noctalia msg panel-toggle jane/daybar:toolbar" "$CALL_LOG"
}

@test "v5 plugin daybar capture -> noctalia msg plugin core all capture" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES="daybar=core@all"

    run_nocta plugin daybar capture

    assert_success
    grep -qx "noctalia msg plugin jane/daybar:core all capture" "$CALL_LOG"
}

@test "v5 plugin gistbar create uses entry from table" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES="daybar=widget gistbar=widget"

    run_nocta plugin gistbar create

    assert_success
    grep -qx "noctalia msg plugin jane/gistbar:widget focused create" "$CALL_LOG"
}

@test "v5 plugin aibar refresh -> noctalia msg plugin usage all refresh" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES="aibar=usage@all"

    run_nocta plugin aibar refresh

    assert_success
    grep -qx "noctalia msg plugin jane/aibar:usage all refresh" "$CALL_LOG"
}

@test "v5 plugin aibar cycle -> noctalia msg plugin usage all cycle" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES="aibar=usage@all"

    run_nocta plugin aibar cycle

    assert_success
    grep -qx "noctalia msg plugin jane/aibar:usage all cycle" "$CALL_LOG"
}

@test "v5 plugin rdo-solo toggle -> noctalia msg plugin live all toggle" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES="rdo-solo=live@all"

    run_nocta plugin rdo-solo toggle

    assert_success
    grep -qx "noctalia msg plugin jane/rdo-solo:live all toggle" "$CALL_LOG"
}

@test "v5 plugin entry@target uses explicit IPC target" {
    FAKE_NOCTALIA_PIDS="2222"
    NOCTA_PLUGIN_ENTRIES="daybar=widget@all"

    run_nocta plugin daybar capture

    assert_success
    grep -qx "noctalia msg plugin jane/daybar:widget all capture" "$CALL_LOG"
}

# ---- niri binds migrate to nocta (Task 3 / REQ-005) ----

@test "niri config has no direct qs noctalia-shell IPC binds" {
    local niri_cfg="$PROJECT_ROOT/configs/niri/config.kdl"
    local qs_hits

    qs_hits="$(grep -cE 'qs" "-c"|qs -c noctalia-shell' "$niri_cfg" || true)"
    [ "$qs_hits" -eq 0 ]
}

@test "niri config drops Mod+Alt+K keybind-cheatsheet bind" {
    local niri_cfg="$PROJECT_ROOT/configs/niri/config.kdl"

    ! grep -qE 'Mod\+Alt\+K|keybind-cheatsheet' "$niri_cfg"
}

@test "niri config routes Noctalia actions through nocta" {
    local niri_cfg="$PROJECT_ROOT/configs/niri/config.kdl"

    # Author plugins (daybar/gistbar) and personal helpers live in private.kdl.
    ! grep -qE 'nocta plugin (daybar|gistbar)|focus-mode|gsr-toggle|grok-bot' "$niri_cfg"
    # RDO binds stay in the private overlay; public config has no rdo-solo.
    ! grep -q 'rdo-solo' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta launcher"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta clipboard"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta control-center"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta settings"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta widgets-edit"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta bar-toggle"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta wallpaper-random"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta lock"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta volume-up"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta volume-down"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta volume-mute"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta brightness-up"' "$niri_cfg"
    grep -q 'spawn-sh "~/.dotfiles/bin/utils/nocta brightness-down"' "$niri_cfg"
}


@test "nocta does nothing without the plugin author" {
    FAKE="$STUB_DIR"; CALLS="$CALL_LOG"
    export FAKE_NOCTALIA_PIDS="1234"
    run env -i HOME="$TEST_DIR" PATH="$STUB_DIR:/usr/bin:/bin" CALL_LOG="$CALL_LOG" FAKE_NOCTALIA_PIDS="1234" bash "$SCRIPT" example open
    [ "$status" -ne 0 ]
    [[ "$output" == *"NOCTALIA_PLUGIN_AUTHOR"* ]]
    [ ! -s "$CALL_LOG" ]
}

@test "nocta uses the plugin author in every plugin id" {
    : > "$CALL_LOG"
    export FAKE_NOCTALIA_PIDS="1234"
    run env -i HOME="$TEST_DIR" PATH="$STUB_DIR:/usr/bin:/bin" CALL_LOG="$CALL_LOG" FAKE_NOCTALIA_PIDS="1234" NOCTALIA_PLUGIN_AUTHOR=jane NOCTA_PLUGIN_ENTRIES="example=widget" bash "$SCRIPT" example open
    [ "$status" -eq 0 ]
    grep -q 'jane/example' "$CALL_LOG"
    ! grep -q 'nan""domoreirame' "$CALL_LOG"
}
