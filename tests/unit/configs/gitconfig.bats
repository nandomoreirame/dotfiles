#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    cp "$ROOT/configs/.gitconfig" "$HOME/.gitconfig"
    : > "$HOME/.gitconfig.local"
    export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" GIT_CONFIG_SYSTEM=/dev/null
}

@test "identity signing and hooks are unset" {
    for k in user.name user.email commit.gpgsign tag.gpgsign core.hooksPath; do
        run git config --get "$k"
        [ "$status" -ne 0 ]
    done
}

@test "the local file is included" {
    printf '[user]\n\tname = Jane Dev\n\temail = jane@example.com\n' > "$HOME/.gitconfig.local"
    run git config --get user.email
    [ "$output" = "jane@example.com" ]
}

@test "the config has no personal rewrite or macos only tool" {
    _a="nando""moreira"
    run grep -niE '${_a}|kaleidoscope|ksdiff|/home/' "$ROOT/configs/.gitconfig"
    [ "$status" -ne 0 ]
}

@test "the config parses and keeps the generic settings" {
    run git config --list
    [ "$status" -eq 0 ]
    run git config --get push.default
    [ "$output" = "current" ]
}

@test "git files are english and have no personal data" {
    _a="nando""moreira"
    run grep -rnE "[áàâãéêíóôõúç]|${_a}|@gmail" "$ROOT/configs/.gitconfig" "$ROOT/configs/git"
    [ "$status" -ne 0 ]
}
