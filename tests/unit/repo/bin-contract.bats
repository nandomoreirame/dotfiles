#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    # Expected test count per helper (source repo numbers; a migrated file may have more).
    declare -gA MIN_TESTS=(
        [sys-btrfs-backup]=12 [sys-clean-cache]=30 [clean-claude-sessions]=40 [notify-open]=8
        [video-to-gif]=8 [localsend-clip]=11 [espanso-hotplug]=5 [droidcam-ctl]=7
    )
    HELPERS=()
    shopt -s nullglob
    for f in "$ROOT"/bin/*/*; do
        [ -f "$f" ] || continue
        HELPERS+=("$f")
    done
    shopt -u nullglob
}

@test "every helper is executable and starts with a shebang" {
    for f in "${HELPERS[@]}"; do
        [ -x "$f" ]
        head -1 "$f" | grep -q '^#!'
    done
}

@test "every helper passes shellcheck" {
    command -v shellcheck >/dev/null || skip "shellcheck not installed"
    [ "${#HELPERS[@]}" -eq 0 ] || shellcheck -x "${HELPERS[@]}"
}

@test "every helper has a test file with the expected test count" {
    for f in "${HELPERS[@]}"; do
        n="$(basename "$f")"
        t="$ROOT/tests/unit/bin/$n.bats"
        [ -f "$t" ]
        want="${MIN_TESTS[$n]:-1}"
        got="$(grep -c '^@test' "$t")"
        [ "$got" -ge "$want" ]
    done
}

@test "every helper has a row in the bin readme" {
    for f in "${HELPERS[@]}"; do
        grep -q "^| \`$(basename "$f")\`" "$ROOT/bin/README.md"
    done
}

@test "helpers and tests contain no personal data" {
    run grep -rnEi "homelab|tailscale|nandomoreira|gabriel|latitude" "$ROOT/bin" "$ROOT/tests/unit/bin"
    [ "$status" -ne 0 ]
    run grep -rnE "\b(10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+)\b|/home/[A-Za-z]" "$ROOT/bin" "$ROOT/tests/unit/bin"
    [ "$status" -ne 0 ]
}

@test "helpers and tests are written in English" {
    run grep -rnE "[áàâãéêíóôõúç]|\b(não|erro|arquivo|falha|uso)\b" "$ROOT/bin" "$ROOT/tests/unit/bin"
    [ "$status" -ne 0 ]
}

@test "the bin readme documents the PATH snippet" {
    grep -q "PATH" "$ROOT/bin/README.md"
}

@test "ci and the clean clone simulation lint the bin directory" {
    grep -qF 'bin/*/*' "$ROOT/.github/workflows/ci.yml"
    grep -qF 'bin/*/*' "$ROOT/scripts/simulate-clean-clone"
}
