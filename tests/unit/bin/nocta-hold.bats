#!/usr/bin/env bats

# Unit tests for bin/utils/nocta-hold (REQ-005 via nocta)
#
# Run:
#   ./tests/run-tests tests/unit/bin/nocta-hold.bats
#
# Stubs `nocta` via NOCTA_BIN. Isolates hold state under XDG_RUNTIME_DIR.

load '../../bats/helpers/setup'
bats_require_minimum_version 1.5.0

SCRIPT="$PROJECT_ROOT/bin/utils/nocta-hold"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"
    RUNTIME_DIR="$TEST_DIR/runtime"

    mkdir -p "$STUB_DIR" "$RUNTIME_DIR"
    : > "$CALL_LOG"

    cat > "$STUB_DIR/nocta" <<'STUB'
#!/usr/bin/env bash
# Log every invocation; answer dnd status from FAKE_DND_STATUS (on|off).
if [ "$#" -eq 0 ]; then
    echo "nocta" >> "$CALL_LOG"
else
    echo "nocta $*" >> "$CALL_LOG"
fi
if [ "${1:-}" = "dnd" ] && [ "${2:-}" = "status" ]; then
    printf '%s\n' "${FAKE_DND_STATUS:-off}"
    exit 0
fi
exit 0
STUB
    chmod +x "$STUB_DIR/nocta"

    export CALL_LOG
    export FAKE_DND_STATUS=off
    export XDG_RUNTIME_DIR="$RUNTIME_DIR"
    export NOCTA_BIN="$STUB_DIR/nocta"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "first dnd acquire with DND off calls nocta dnd on" {
    run "$SCRIPT" dnd acquire a

    [ "$status" -eq 0 ]
    grep -qx "nocta dnd on" "$CALL_LOG"
}

@test "last dnd release calls nocta dnd off" {
    "$SCRIPT" dnd acquire a
    : > "$CALL_LOG"

    run "$SCRIPT" dnd release a

    [ "$status" -eq 0 ]
    grep -qx "nocta dnd off" "$CALL_LOG"
}

@test "dnd already on at first acquire is never turned off" {
    export FAKE_DND_STATUS=on

    run "$SCRIPT" dnd acquire a
    [ "$status" -eq 0 ]
    ! grep -qx "nocta dnd on" "$CALL_LOG"

    : > "$CALL_LOG"
    run "$SCRIPT" dnd release a
    [ "$status" -eq 0 ]
    ! grep -qx "nocta dnd off" "$CALL_LOG"
}

@test "awake acquire/release calls nocta awake on|off" {
    run "$SCRIPT" awake acquire keep
    [ "$status" -eq 0 ]
    grep -qx "nocta awake on" "$CALL_LOG"

    : > "$CALL_LOG"
    run "$SCRIPT" awake release keep
    [ "$status" -eq 0 ]
    ! grep -qx "nocta awake on" "$CALL_LOG"
    grep -qx "nocta awake off" "$CALL_LOG"
}

@test "second dnd hold does not re-enable; partial release keeps dnd on" {
    "$SCRIPT" dnd acquire a
    : > "$CALL_LOG"

    run "$SCRIPT" dnd acquire b
    [ "$status" -eq 0 ]
    ! grep -qx "nocta dnd on" "$CALL_LOG"

    run "$SCRIPT" dnd release a
    [ "$status" -eq 0 ]
    ! grep -qx "nocta dnd off" "$CALL_LOG"
}

@test "dnd status failure is treated as off and acquire still turns dnd on" {
    cat > "$STUB_DIR/nocta" <<'STUB'
#!/usr/bin/env bash
if [ "$#" -eq 0 ]; then
    echo "nocta" >> "$CALL_LOG"
else
    echo "nocta $*" >> "$CALL_LOG"
fi
if [ "${1:-}" = "dnd" ] && [ "${2:-}" = "status" ]; then
    exit 1
fi
exit 0
STUB
    chmod +x "$STUB_DIR/nocta"

    run "$SCRIPT" dnd acquire a

    [ "$status" -eq 0 ]
    grep -qx "nocta dnd on" "$CALL_LOG"
}

@test "active exits 0 with a hold and 1 without" {
    run "$SCRIPT" dnd active
    [ "$status" -ne 0 ]

    "$SCRIPT" dnd acquire a
    run "$SCRIPT" dnd active
    [ "$status" -eq 0 ]
}

@test "status lists active holds" {
    "$SCRIPT" dnd acquire owner-a
    "$SCRIPT" awake acquire owner-b

    run "$SCRIPT" status

    [ "$status" -eq 0 ]
    [[ "$output" == *"dnd"* ]]
    [[ "$output" == *"owner-a"* ]]
    [[ "$output" == *"awake"* ]]
    [[ "$output" == *"owner-b"* ]]
}

@test "user-facing messages are English" {
    run "$SCRIPT" bogus acquire x
    [ "$status" -ne 0 ]
    [[ "$output" == *"usage:"* ]]
    [[ "$output" != *"uso:"* ]]
    [[ "$output" != *"recurso"* ]]

    run "$SCRIPT" dnd acquire
    [ "$status" -ne 0 ]
    [[ "$output" == *"owner required"* ]]
    [[ "$output" != *"obrigatorio"* ]]

    run "$SCRIPT" dnd nope owner-a
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid action"* ]]
    [[ "$output" != *"acao"* ]]
}

@test "status uses English active/inactive labels" {
    "$SCRIPT" dnd acquire owner-a
    run "$SCRIPT" status
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACTIVE"* ]]
    [[ "$output" != *"ATIVO"* ]]
    [[ "$output" != *"inativo"* ]]
    [[ "$output" != *"preexistente"* ]]
}

@test "rejects unsafe owner names" {
    for owner in '../x' 'a/b' 'a/../b' '..'; do
        run "$SCRIPT" dnd acquire "$owner"
        [ "$status" -ne 0 ]
        [[ "$output" == *"invalid owner"* ]]
    done
    # No hold markers created via path traversal
    [ ! -e "$XDG_RUNTIME_DIR/nocta-hold/x" ]
    [ ! -e "$XDG_RUNTIME_DIR/nocta-hold/dnd/a" ]
    [ ! -e "$XDG_RUNTIME_DIR/nocta-hold/dnd/b" ]
    # Only the lock file should exist under the hold root after rejected acquires
    ! find "$XDG_RUNTIME_DIR/nocta-hold/dnd" -type f 2>/dev/null | grep -q .
}
