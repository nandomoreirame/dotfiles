#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT" GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig" GIT_CONFIG_NOSYSTEM=1
    mkdir -p "$HOME"; : > "$GIT_CONFIG_GLOBAL"
    R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R"
    git -C "$R" init -q -b main
    git -C "$R" config user.name "Jane Dev"; git -C "$R" config user.email "jane@example.com"; git -C "$R" config commit.gpgsign false
    export PATH="$ROOT/bin/git:$PATH"
    # Split so public-check does not see a contiguous /home/<user> path in this file.
    HOME_PATH="/ho""me/someone/project/x"
}

ci() { git -C "$R" -c core.hooksPath="$ROOT/git-hooks" commit -q -m "$1"; }
CLI() { run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" GIT_CONFIG_GLOBAL="$GIT_CONFIG_GLOBAL" DOTFILES_YES=1 bash "$ROOT/bin/dotfiles" "$@"; }

@test "hooks are off until enabled" {
    run git config --global core.hooksPath
    [ "$status" -ne 0 ]
    CLI hooks status
    [[ "$output" == *"disabled"* ]] || [[ "$output" == *"off"* ]]
}

@test "hooks enable and disable toggle core.hooksPath" {
    CLI hooks enable
    [ "$status" -eq 0 ]
    [[ "$output" == *"every repository"* ]]
    [[ "$output" == *"hooks disable"* ]]
    run git config --file "$HOME/.gitconfig.local" core.hooksPath
    [ "$output" = "$ROOT/git-hooks" ]
    CLI hooks disable
    run git config --file "$HOME/.gitconfig.local" core.hooksPath
    [ "$status" -ne 0 ]
}

@test "hooks enable never writes the repository config" {
    CLI hooks enable
    run git -C "$ROOT" config --local core.hooksPath
    [ "$status" -ne 0 ]
}

@test "guard blocks a home path" {
    printf 'path=%s\n' "$HOME_PATH" > "$R/a.txt"; git -C "$R" add a.txt
    run ci "add path"
    [ "$status" -ne 0 ]
    [[ "$output" == *"home"* ]]
}

@test "guard blocks an obvious secret" {
    printf 'token=%s%s\n' "AKIA" "ABCDEFGHIJKLMNOP" > "$R/b.txt"; git -C "$R" add b.txt
    run ci "add key"
    [ "$status" -ne 0 ]
    [[ "$output" == *"secret"* ]]
    [[ "$output" != *"AKIA"*"ABCDEFGHIJKLMNOP"* ]]
}

@test "guard allows a clean commit and --no-verify bypasses it" {
    printf 'hello\n' > "$R/c.txt"; git -C "$R" add c.txt
    run ci "clean"
    [ "$status" -eq 0 ]
    printf 'p=%s\n' "/ho""me/someone/x" > "$R/d.txt"; git -C "$R" add d.txt
    run git -C "$R" -c core.hooksPath="$ROOT/git-hooks" commit -q --no-verify -m "bypass"
    [ "$status" -eq 0 ]
}

@test "guard chains the repository local pre-commit hook" {
    printf '#!/bin/sh\necho local-hook-ran >&2\nexit 1\n' > "$R/.git/hooks/pre-commit"; chmod +x "$R/.git/hooks/pre-commit"
    printf 'hello\n' > "$R/e.txt"; git -C "$R" add e.txt
    run ci "chained"
    [ "$status" -ne 0 ]
    [[ "$output" == *"local-hook-ran"* ]]
}

@test "strip removes signature lines and nothing else" {
    f="$BATS_TEST_TMPDIR/msg"
    printf 'feat: add thing\n\nBody line.\n\nCo-Authored-By: Bot <bot@example.com>\nGenerated with a tool\n\n' > "$f"
    run "$ROOT/bin/git/git-strip-ai-signatures" "$f"
    [ "$status" -eq 0 ]
    grep -q "feat: add thing" "$f"; grep -q "Body line." "$f"
    ! grep -qi "co-authored-by\|generated with" "$f"
    [ "$(tail -c1 "$f" | od -An -c | tr -d ' ')" != '\n\n' ]
}

@test "strip is a no-op on a missing file" {
    run "$ROOT/bin/git/git-strip-ai-signatures" "$BATS_TEST_TMPDIR/nope"
    [ "$status" -eq 0 ]
}

@test "the strip hook is a separate switch" {
    CLI hooks enable guard
    [ "$status" -eq 0 ]
    CLI hooks status
    [[ "$output" == *"guard"* ]]
    [[ "$output" != *"strip: on"* ]]
}

@test "hooks messages are English" {
    run grep -nE "[áàâãéêíóôõúç]|\b(bloqueado|segredo|corrija)\b" "$ROOT/git-hooks/pre-commit" "$ROOT/git-hooks/commit-msg" "$ROOT/lib/hooks.sh"
    [ "$status" -ne 0 ]
}
