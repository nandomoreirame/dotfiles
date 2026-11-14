#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    HOME_DECOY="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME_DECOY"
    ln -s "$ROOT/configs/.zshenv" "$HOME_DECOY/.zshenv"
}

zrun() { run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" zsh -f -c "source '$HOME_DECOY/.zshenv'; $1"; }

@test "dotfiles resolves through a symlink under a decoy home" {
    zrun 'print -r -- $DOTFILES'
    [ "$status" -eq 0 ]
    [ "$output" = "$ROOT" ]
}

@test "an exported dotfiles wins over the derived one" {
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES=/srv/example/dot zsh -f -c "source '$HOME_DECOY/.zshenv'; print -r -- \$DOTFILES"
    [ "$output" = "/srv/example/dot" ]
}

@test "private bin joins the path only when it exists" {
    zrun 'print -l $path'
    [[ "$output" != *"/private/bin"* ]]
    mkdir -p "$ROOT/private/bin"
    zrun 'print -l $path'
    rmdir "$ROOT/private/bin"
    [[ "$output" == *"$ROOT/private/bin"* ]]
}

@test "the path has no duplicates" {
    zrun 'print -l $path | sort | uniq -d'
    [ -z "$output" ]
}

@test "zshenv prints nothing without private" {
    zrun 'true'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "bashrc and profile load without errors" {
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" bash --noprofile --norc -c ". '$ROOT/configs/.bashrc'; . '$ROOT/configs/.profile'"
    [ "$status" -eq 0 ]
}

@test "shell env files hard-code no home dotfiles path or token file" {
    run grep -nE 'HOME/\.dotfiles|~/\.dotfiles|stitch|typesafe|marginalia|homelab' "$ROOT/configs/.zshenv" "$ROOT/configs/.bashrc" "$ROOT/configs/.profile"
    [ "$status" -ne 0 ]
}
