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
    override="$BATS_TEST_TMPDIR/override"
    mkdir -p "$override"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES="$override" zsh -f -c "source '$HOME_DECOY/.zshenv'; print -r -- \$DOTFILES"
    [ "$output" = "$override" ]
}

@test "a missing exported DOTFILES is re-derived from the zshenv path" {
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES=/nonexistent/dotfiles \
        zsh -f -c "source '$HOME_DECOY/.zshenv'; print -r -- \$DOTFILES"
    [ "$status" -eq 0 ]
    [ "$output" = "$ROOT" ]
}

@test "a missing exported DOTFILES_PRIVATE is dropped" {
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES_PRIVATE=/nonexistent/private \
        zsh -f -c "source '$HOME_DECOY/.zshenv'; print -r -- \${DOTFILES_PRIVATE-UNSET}"
    [ "$status" -eq 0 ]
    [ "$output" = "UNSET" ]
}

@test "private bin joins the path only when it exists" {
    # Disposable clone: a real private/bin overlay must not flake this check.
    dot="$BATS_TEST_TMPDIR/path-dot"
    mkdir -p "$dot/configs"
    cp "$ROOT/configs/.zshenv" "$dot/configs/.zshenv"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" \
        zsh -f -c "source '$dot/configs/.zshenv'; print -l \$path"
    [[ "$output" != *"/private/bin"* ]]
    mkdir -p "$dot/private/bin"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" \
        zsh -f -c "source '$dot/configs/.zshenv'; print -l \$path"
    [[ "$output" == *"$dot/private/bin"* ]]
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

@test "private env files are sourced in name order for every zsh" {
    dot="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$dot/private/env"
    printf 'export A=1\n' > "$dot/private/env/10-a.zsh"
    printf 'export B="${A}2"\n' > "$dot/private/env/20-b.zsh"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES="$dot" zsh -f -c "source '$HOME_DECOY/.zshenv'; print -r -- \$B"
    [ "$status" -eq 0 ]
    [ "$output" = "12" ]
}

@test "the private env hook honors DOTFILES_PRIVATE" {
    ov="$BATS_TEST_TMPDIR/overlay"
    mkdir -p "$ov/env"
    printf 'export C=ok\n' > "$ov/env/10-c.zsh"
    run env -i HOME="$HOME_DECOY" PATH="/usr/bin:/bin" DOTFILES_PRIVATE="$ov" zsh -f -c "source '$HOME_DECOY/.zshenv'; print -r -- \$C"
    [ "$output" = "ok" ]
}
