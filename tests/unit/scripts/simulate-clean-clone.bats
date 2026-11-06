#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

@test "clean clone simulation passes" {
    [ -z "$SIMULATE_ACTIVE" ] || skip "running inside the simulation"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color bash "$ROOT/scripts/simulate-clean-clone" --worktree
    [ "$status" -eq 0 ]
    [[ "$output" == *"tests: ok"* ]]
    [[ "$output" == *"shellcheck: ok"* ]]
    [[ "$output" == *"public-check: ok"* ]]
}

@test "simulation uses a temporary home" {
    run grep -n "mktemp" "$ROOT/scripts/simulate-clean-clone"
    [ "$status" -eq 0 ]
}

@test "simulation stops on the first failing stage" {
    [ -z "$SIMULATE_ACTIVE" ] || skip "running inside the simulation"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color SIMULATE_FAIL_STAGE=shellcheck bash "$ROOT/scripts/simulate-clean-clone" --worktree
    [ "$status" -ne 0 ]
    [[ "$output" != *"public-check: ok"* ]]
}

@test "the repository passes its own gate" {
    run bash "$ROOT/scripts/public-check" "$ROOT"
    [ "$status" -eq 0 ]
}

@test "the repository scripts pass shellcheck" {
    command -v shellcheck >/dev/null || skip "shellcheck not installed"
    run shellcheck -x "$ROOT"/scripts/public-check "$ROOT"/scripts/simulate-clean-clone "$ROOT"/lib/private.sh "$ROOT"/tests/run-tests
    [ "$status" -eq 0 ]
}

@test "worktree mode tolerates a tracked file deleted from disk" {
    [ -z "$SIMULATE_ACTIVE" ] || skip "running inside the simulation"
    R="$BATS_TEST_TMPDIR/mini"
    mkdir -p "$R/scripts" "$R/tests" "$R/lib"
    cp "$ROOT/scripts/simulate-clean-clone" "$R/scripts/simulate-clean-clone"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$R/scripts/public-check"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$R/tests/run-tests"
    printf '#!/usr/bin/env bash\n:\n' > "$R/lib/x.sh"
    echo gone > "$R/gone.txt"
    git -C "$R" init -q -b main
    git -C "$R" add -A
    git -C "$R" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm base
    rm "$R/gone.txt"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color bash "$R/scripts/simulate-clean-clone" --worktree
    [ "$status" -eq 0 ]
    [[ "$output" == *"tests: ok"* ]]
}
