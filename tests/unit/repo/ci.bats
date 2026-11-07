#!/usr/bin/env bats

setup() { WF="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)/.github/workflows/ci.yml"; }

@test "ci runs the gate with least privilege" {
    [ -f "$WF" ]
    grep -q "scripts/public-check" "$WF"
    grep -qE "^permissions:" "$WF"
    grep -q "contents: read" "$WF"
}

@test "ci checks out recursive submodules" {
    grep -q "submodules: recursive" "$WF"
}

@test "ci runs shellcheck tests and gitleaks" {
    grep -q "shellcheck" "$WF"
    grep -q "tests/run-tests" "$WF"
    grep -qi "gitleaks" "$WF"
}

@test "ci never uses pull_request_target" {
    run grep -n "pull_request_target" "$WF"
    [ "$status" -ne 0 ]
}

@test "ci pins third party actions to a version" {
    run grep -nE "uses: [^@]+$|uses: [^@]+@(main|master|latest)$" "$WF"
    [ "$status" -ne 0 ]
}

@test "ci triggers on push and pull_request for main" {
    grep -q "push:" "$WF"
    grep -q "pull_request:" "$WF"
    grep -q "main" "$WF"
}

@test "ci shellchecks the bin directory" {
    grep -qF 'bin/*/*' "$WF"
}
