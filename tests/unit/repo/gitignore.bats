#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

@test "docs planning files are ignored" {
    for p in docs/plans/x.md docs/specs/x/SPEC.md docs/specs/x/STATE.md docs/reviews/x.md docs/anything.md; do
        run git -C "$ROOT" check-ignore -q "$p"
        [ "$status" -eq 0 ]
    done
}

@test "docs is ignored as a whole, with no exception" {
    run git -C "$ROOT" check-ignore -q docs/private-overlay.md
    [ "$status" -eq 0 ]
    run grep -nE '^!/?docs' "$ROOT/.gitignore"
    [ "$status" -ne 0 ]
}

@test "only the two overlay docs under private are not ignored" {
    for p in private/README.md private/private-overlay.md; do
        run git -C "$ROOT" check-ignore -q "$p"
        [ "$status" -ne 0 ]
    done
    for p in private/bin/x private/secret.txt private/shell/a.zsh private/links.conf; do
        run git -C "$ROOT" check-ignore -q "$p"
        [ "$status" -eq 0 ]
    done
}

@test "private and secrets are ignored" {
    for p in private/a .env .env.local x.local; do
        run git -C "$ROOT" check-ignore -q "$p"
        [ "$status" -eq 0 ]
    done
}

@test "no file under docs is tracked" {
    run git -C "$ROOT" ls-files docs
    [ -z "$output" ]
}
