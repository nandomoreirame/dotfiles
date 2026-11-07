#!/usr/bin/env bats

# Unit tests for bin/utils/espanso-hotplug and the udev/systemd glue around it
#
# Run:
#   ./tests/run-tests unit/bin/espanso-hotplug.bats
#
# Coverage:
#   - A keyboard plugged in while espanso runs restarts the espanso service
#     (regression: a USB reset re-enumerated the keyboard on new event nodes
#     and the EVDEV backend kept running blind, still "running")
#   - espanso stopped is a no-op (hotplug never starts it behind the user)
#   - espanso started less than the grace period ago is a no-op, which covers
#     the burst of event nodes per keyboard and the login-time enumeration
#   - The udev rule matches keyboard event nodes and wants the user unit
#   - The user unit runs this helper as a oneshot
#
# `systemctl` is stubbed on PATH: FAKE_ACTIVE drives `is-active` and
# FAKE_SINCE the ActiveEnterTimestamp; calls are recorded in CALL_LOG.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/espanso-hotplug"
UDEV_RULE="$PROJECT_ROOT/configs/udev/90-espanso-keyboard-hotplug.rules"
USER_UNIT="$PROJECT_ROOT/configs/systemd/user/espanso-hotplug.service"
NOW=1792856800

setup() {
    mock_init
    CALL_LOG="$MOCK_DIR/calls.log"
    : > "$CALL_LOG"
    mock_command "systemctl" "
echo \"systemctl \$*\" >> '$CALL_LOG'
case \"\$*\" in
    *is-active*) [ \"\${FAKE_ACTIVE:-yes}\" = yes ] ;;
    *ActiveEnterTimestamp*) echo \"@\${FAKE_SINCE:-0}\" ;;
esac
"
}

teardown() {
    mock_cleanup
}

_run_script() {
    # env -i: BASH_ENV/~/.bashrc re-prepends PATH and would hide MOCK_DIR stubs.
    run env -i \
        HOME="$HOME" \
        FAKE_ACTIVE="${FAKE_ACTIVE:-yes}" \
        FAKE_SINCE="${FAKE_SINCE:-0}" \
        ESPANSO_HOTPLUG_NOW="$NOW" \
        ESPANSO_HOTPLUG_GRACE=10 \
        PATH="$MOCK_DIR:/usr/bin:/bin" \
        bash --noprofile --norc "$SCRIPT" "$@"
}

@test "running espanso past the grace period restarts the service" {
    FAKE_SINCE=$((NOW - 3600)) _run_script
    assert_success

    run grep -E '^systemctl --user restart espanso\.service$' "$CALL_LOG"
    assert_success
}

@test "stopped espanso does not restart or start" {
    FAKE_ACTIVE=no _run_script
    assert_success

    run grep -E 'restart|start espanso' "$CALL_LOG"
    assert_failure
}

@test "espanso started within the grace period does not restart again" {
    FAKE_SINCE=$((NOW - 3)) _run_script
    assert_success

    run grep -E 'restart' "$CALL_LOG"
    assert_failure
}

@test "udev rule matches keyboard event nodes and wants the user unit" {
    run grep -E 'ACTION=="add"' "$UDEV_RULE"
    assert_success
    run grep -E 'SUBSYSTEM=="input"' "$UDEV_RULE"
    assert_success
    run grep -E 'KERNEL=="event\*"' "$UDEV_RULE"
    assert_success
    run grep -E 'ENV\{ID_INPUT_KEYBOARD\}=="1"' "$UDEV_RULE"
    assert_success
    run grep -E 'TAG\+="systemd"' "$UDEV_RULE"
    assert_success
    run grep -E 'ENV\{SYSTEMD_USER_WANTS\}\+="espanso-hotplug\.service"' "$UDEV_RULE"
    assert_success
}

@test "user unit is oneshot and runs the helper" {
    run grep -E '^Type=oneshot$' "$USER_UNIT"
    assert_success
    run grep -E '^ExecStart=/usr/bin/env espanso-hotplug$' "$USER_UNIT"
    assert_success
}
