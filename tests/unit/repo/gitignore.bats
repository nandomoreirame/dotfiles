#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

@test "docs planning files are ignored" {
    for p in docs/plans/x.md docs/specs/x/SPEC.md docs/specs/x/STATE.md docs/reviews/x.md docs/anything.md; do
        run git -C "$ROOT" check-ignore -q "$p"
        [ "$status" -eq 0 ]
    done
}

@test "the overlay doc is not ignored" {
    run git -C "$ROOT" check-ignore -q docs/private-overlay.md
    [ "$status" -ne 0 ]
}

@test "private and secrets are ignored" {
    for p in private/a .env .env.local x.local; do
        run git -C "$ROOT" check-ignore -q "$p"
        [ "$status" -eq 0 ]
    done
}

@test "no planning document is tracked" {
    run git -C "$ROOT" ls-files docs/plans docs/specs docs/reviews
    [ -z "$output" ]
}
