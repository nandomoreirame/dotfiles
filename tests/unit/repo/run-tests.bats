#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    SUITE="$BATS_TEST_TMPDIR/suite"
    mkdir -p "$SUITE"
}

runner() { env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM="${TERM_OVERRIDE:-xterm-256color}" bash "$ROOT/tests/run-tests" "$@"; }

@test "run-tests fails when a test fails" {
    printf '#!/usr/bin/env bats\n@test "boom" { false; }\n' > "$SUITE/fail.bats"
    run runner "$SUITE/fail.bats"
    [ "$status" -ne 0 ]
}

@test "run-tests passes a green file" {
    printf '#!/usr/bin/env bats\n@test "fine" { true; }\n' > "$SUITE/ok.bats"
    run runner "$SUITE/ok.bats"
    [ "$status" -eq 0 ]
}

@test "run-tests copes with TERM=dumb" {
    printf '#!/usr/bin/env bats\n@test "fine" { true; }\n' > "$SUITE/ok.bats"
    TERM_OVERRIDE=dumb run runner "$SUITE/ok.bats"
    [ "$status" -eq 0 ]
}

@test "run-tests explains a missing submodule" {
    mkdir -p "$BATS_TEST_TMPDIR/bare/tests"
    cp "$ROOT/tests/run-tests" "$BATS_TEST_TMPDIR/bare/tests/run-tests"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color bash "$BATS_TEST_TMPDIR/bare/tests/run-tests"
    [ "$status" -eq 2 ]
    [[ "$output" == *"git submodule update --init --recursive"* ]]
}

@test "run-tests maps the group names unit and integration" {
    run grep -nE "unit|integration" "$ROOT/tests/run-tests"
    [ "$status" -eq 0 ]
}
