#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

@test "pull request template has the personal data checklist" {
    f="$ROOT/.github/PULL_REQUEST_TEMPLATE.md"
    [ -f "$f" ]
    grep -qi "personal data" "$f"
    grep -q "scripts/public-check" "$f"
    grep -q "tests/run-tests" "$f"
}

@test "issue templates exist and are valid forms" {
    for t in bug request; do
        f="$ROOT/.github/ISSUE_TEMPLATE/$t.yml"
        [ -f "$f" ]
        grep -q "^name:" "$f"
        grep -q "^body:" "$f"
    done
}

@test "bug template asks for the distribution and warns against secrets" {
    grep -qi "distribution" "$ROOT/.github/ISSUE_TEMPLATE/bug.yml"
    grep -qi "secret\|token\|personal" "$ROOT/.github/ISSUE_TEMPLATE/bug.yml"
}

@test "changelog follows keep a changelog" {
    grep -q "Keep a Changelog" "$ROOT/CHANGELOG.md"
    grep -q "^## \[Unreleased\]" "$ROOT/CHANGELOG.md"
}
