#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

@test "license is MIT" {
    head -1 "$ROOT/LICENSE" | grep -q "MIT License"
    grep -q "Copyright (c) 2026 Fernando Moreira Costa" "$ROOT/LICENSE"
}

@test "readme opens with the problem and states the status" {
    sed -n 1,20p "$ROOT/README.md" | grep -qiE "new machine|from scratch|setting up"
    grep -q "^## Status" "$ROOT/README.md"
    grep -qi "under construction" "$ROOT/README.md"
    grep -q "^## Requirements" "$ROOT/README.md"
    grep -q "^## Security" "$ROOT/README.md"
    grep -q "^## License" "$ROOT/README.md"
}

@test "third-party notes list bats and exclude fonts wallpapers and icons" {
    grep -qi "bats" "$ROOT/THIRD-PARTY.md"
    grep -qi "fonts" "$ROOT/THIRD-PARTY.md"
    grep -qi "wallpapers" "$ROOT/THIRD-PARTY.md"
    grep -qi "icons" "$ROOT/THIRD-PARTY.md"
}

@test "contributing states the test command and the no personal data rule" {
    grep -q "tests/run-tests" "$ROOT/CONTRIBUTING.md"
    grep -qi "personal data" "$ROOT/CONTRIBUTING.md"
    grep -q "scripts/public-check" "$ROOT/CONTRIBUTING.md"
}

@test "gitignore keeps docs local and protects the overlay" {
    grep -qx "docs/\*" "$ROOT/.gitignore"
    grep -qx "!docs/private-overlay.md" "$ROOT/.gitignore"
    grep -qx "/private/" "$ROOT/.gitignore"
}

@test "shellcheck follows sources" {
    grep -q "external-sources=true" "$ROOT/.shellcheckrc"
}

@test "editorconfig sets utf-8 and lf" {
    grep -q "charset = utf-8" "$ROOT/.editorconfig"
    grep -q "end_of_line = lf" "$ROOT/.editorconfig"
}

@test "no file carries a home directory path" {
    run git -C "$ROOT" grep --untracked -nE "/home/[A-Za-z]" -- . ':!tests/bats/lib'
    [ "$status" -ne 0 ]
}
