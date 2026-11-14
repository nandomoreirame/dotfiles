#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    STRIP="$ROOT/bin/git/git-strip-ai-signatures"
}

@test "git-strip-ai-signatures is executable" {
    [ -x "$STRIP" ]
}

@test "git-strip-ai-signatures strips Co-Authored-By lines" {
    f="$BATS_TEST_TMPDIR/msg"
    printf 'subject\n\nCo-Authored-By: Bot <bot@example.com>\n' > "$f"
    run "$STRIP" "$f"
    [ "$status" -eq 0 ]
    ! grep -qi "co-authored-by" "$f"
    grep -q "subject" "$f"
}
