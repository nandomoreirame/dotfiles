#!/usr/bin/env bats

# Unit tests for bin/utils/niri-bar-autoplace
#
# Run:
#   ./tests/run-tests unit/bin/niri-bar-autoplace.bats
#
# `niri` is stubbed on PATH: it answers `msg --json outputs` from FAKE_OUTPUTS,
# or fails when FAKE_NIRI_FAIL=1. The Noctalia v5 overrides file is a temp copy
# passed through NOCTALIA_OVERRIDES. An output counts as active when niri lists
# it with a non-null `logical` block (a powered-off output has `logical: null`).

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/niri-bar-autoplace"

HEADER='[bar.main.monitor.edp1]'
DOCKED='{"HDMI-A-1":{"name":"HDMI-A-1","logical":{"x":0,"y":0}},"eDP-1":{"name":"eDP-1","logical":{"x":2560,"y":0}}}'
UNDOCKED='{"eDP-1":{"name":"eDP-1","logical":{"x":0,"y":0}}}'

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    mkdir -p "$STUB_DIR"

    cat > "$STUB_DIR/niri" <<'STUB'
#!/usr/bin/env bash
[ "${FAKE_NIRI_FAIL:-0}" = 1 ] && exit 1
if [ "$1" = "msg" ] && [ "$2" = "--json" ] && [ "$3" = "outputs" ]; then
    printf '%s\n' "$FAKE_OUTPUTS"
    exit 0
fi
exit 1
STUB
    chmod +x "$STUB_DIR/niri"

    export NOCTALIA_OVERRIDES="$TEST_DIR/state/settings.toml"
    mkdir -p "$TEST_DIR/state"
    cat > "$NOCTALIA_OVERRIDES" <<'TOML'
config_version = 15

[bar.main]
padding = 12

[theme]
mode = "dark"
TOML
    cp "$NOCTALIA_OVERRIDES" "$TEST_DIR/original.toml"

    export PATH="$STUB_DIR:$PATH"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "leaves the overrides untouched while the middle monitor is active" {
    export FAKE_OUTPUTS="$DOCKED"

    run "$SCRIPT" --once

    [ "$status" -eq 0 ]
    cmp -s "$NOCTALIA_OVERRIDES" "$TEST_DIR/original.toml"
}

@test "enables the bar on eDP-1 when the middle monitor is disconnected" {
    export FAKE_OUTPUTS="$UNDOCKED"

    run "$SCRIPT" --once

    [ "$status" -eq 0 ]
    run sed -n '/^\[bar\.main\.monitor\.edp1\]/,/^\[/p' "$NOCTALIA_OVERRIDES"
    [[ "$output" == *'match = "eDP-1"'* ]]
    [[ "$output" == *"enabled = true"* ]]
    grep -Fqx 'padding = 12' "$NOCTALIA_OVERRIDES"
    grep -Fqx 'mode = "dark"' "$NOCTALIA_OVERRIDES"
}

@test "enables the bar on eDP-1 when the middle monitor is powered off" {
    export FAKE_OUTPUTS='{"HDMI-A-1":{"name":"HDMI-A-1","logical":null},"eDP-1":{"name":"eDP-1","logical":{"x":0,"y":0}}}'

    run "$SCRIPT" --once

    [ "$status" -eq 0 ]
    grep -Fqx "$HEADER" "$NOCTALIA_OVERRIDES"
}

@test "does not duplicate the override on repeated ticks" {
    export FAKE_OUTPUTS="$UNDOCKED"

    "$SCRIPT" --once
    "$SCRIPT" --once

    [ "$(grep -cF "$HEADER" "$NOCTALIA_OVERRIDES")" -eq 1 ]
}

@test "removes the override when the middle monitor comes back" {
    export FAKE_OUTPUTS="$UNDOCKED"
    "$SCRIPT" --once
    export FAKE_OUTPUTS="$DOCKED"

    run "$SCRIPT" --once

    [ "$status" -eq 0 ]
    ! grep -qF "$HEADER" "$NOCTALIA_OVERRIDES"
    ! grep -qF 'match = "eDP-1"' "$NOCTALIA_OVERRIDES"
    grep -Fqx 'padding = 12' "$NOCTALIA_OVERRIDES"
    grep -Fqx 'mode = "dark"' "$NOCTALIA_OVERRIDES"
}

@test "removes an indented override written back by Noctalia without eating the next table" {
    cat > "$NOCTALIA_OVERRIDES" <<'TOML'
[bar.main]
padding = 12

    [bar.main.monitor.edp1]
    enabled = true
    match = "eDP-1"

[theme]
mode = "dark"
TOML
    export FAKE_OUTPUTS="$DOCKED"

    run "$SCRIPT" --once

    [ "$status" -eq 0 ]
    ! grep -qF "$HEADER" "$NOCTALIA_OVERRIDES"
    grep -Fqx '[theme]' "$NOCTALIA_OVERRIDES"
    grep -Fqx 'mode = "dark"' "$NOCTALIA_OVERRIDES"
}

@test "creates the overrides file when it does not exist yet" {
    rm -f "$NOCTALIA_OVERRIDES"
    export FAKE_OUTPUTS="$UNDOCKED"

    run "$SCRIPT" --once

    [ "$status" -eq 0 ]
    grep -Fqx "$HEADER" "$NOCTALIA_OVERRIDES"
}

@test "changes nothing when niri cannot be queried" {
    export FAKE_NIRI_FAIL=1

    run "$SCRIPT" --once

    cmp -s "$NOCTALIA_OVERRIDES" "$TEST_DIR/original.toml"
}

@test "changes nothing when niri returns invalid JSON" {
    export FAKE_OUTPUTS='not json'

    run "$SCRIPT" --once

    cmp -s "$NOCTALIA_OVERRIDES" "$TEST_DIR/original.toml"
}

@test "clears a fallback-only overrides file when the middle monitor returns" {
    # Only the edp1 override table — removing it yields an empty file that must
    # still replace the overrides path (otherwise the override sticks forever).
    cat > "$NOCTALIA_OVERRIDES" <<'TOML'
[bar.main.monitor.edp1]
enabled = true
match = "eDP-1"
TOML
    export FAKE_OUTPUTS="$DOCKED"

    run "$SCRIPT" --once

    [ "$status" -eq 0 ]
    [ -f "$NOCTALIA_OVERRIDES" ]
    [ ! -s "$NOCTALIA_OVERRIDES" ]
    ! grep -qF "$HEADER" "$NOCTALIA_OVERRIDES"
}
