#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$HOME" "$DOTFILES/configs/tool" "$DOTFILES/private/tool"
    printf 'plain\n' > "$DOTFILES/configs/.sample"
    printf 'a\n' > "$DOTFILES/configs/tool/conf"; printf 'b\n' > "$DOTFILES/private/tool/secret.conf"
    printf '[files]\n.sample\n\n[paths]\nconfigs/tool/conf | .config/tool/conf |\n' > "$DOTFILES/configs/links.conf"
    printf '[paths]\nprivate/tool/secret.conf | .config/tool/secret.conf |\n' > "$DOTFILES/private/links.conf"
    CLI() { env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$DOTFILES" bash "$ROOT/bin/dotfiles" "$@"; }
}

@test "links all then verify succeeds and a second run changes nothing" {
    run CLI links --all
    [ "$status" -eq 0 ]
    [ -L "$HOME/.sample" ]
    [ -L "$HOME/.config/tool/conf" ]
    [ -L "$HOME/.config/tool/secret.conf" ]
    before="$(find "$HOME" -type l -printf '%p -> %l %i %T@\n' | sort)"
    run CLI links --all
    [ "$status" -eq 0 ]
    [ "$before" = "$(find "$HOME" -type l -printf '%p -> %l %i %T@\n' | sort)" ]
    run CLI --verify
    [ "$status" -eq 0 ]
}

@test "a pre-existing file is backed up, not lost" {
    printf 'mine\n' > "$HOME/.sample"
    run CLI links --files
    [ "$status" -eq 0 ]
    [ -L "$HOME/.sample" ]
    grep -rq "mine" "$HOME" --include='*sample*' --exclude-dir=.config
}

@test "verify fails after a link is removed" {
    CLI links --all >/dev/null
    rm "$HOME/.config/tool/secret.conf"
    run CLI --verify
    [ "$status" -ne 0 ]
}
