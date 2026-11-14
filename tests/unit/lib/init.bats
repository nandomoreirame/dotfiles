#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    mkdir -p "$HOME"
}

@test "init writes gitconfig.local and not the repo" {
    run bash -c "printf 'Jane Dev\njane@example.com\n' | env -i HOME='$HOME' PATH=/usr/bin:/bin DOTFILES='$ROOT' DOTFILES_PROMPT_STDIN=1 TERM=xterm-256color bash -c \"source '$ROOT/lib/init.sh'; _dotfiles_init\""
    [ "$status" -eq 0 ]
    grep -q "name = Jane Dev" "$HOME/.gitconfig.local"
    grep -q "email = jane@example.com" "$HOME/.gitconfig.local"
    run git -C "$ROOT" status --porcelain -- configs
    [ -z "$output" ]
}

@test "init keeps existing values unless confirmed" {
    printf '[user]\n\tname = Keep Me\n\temail = keep@example.com\n' > "$HOME/.gitconfig.local"
    run bash -c "printf 'n\n' | env -i HOME='$HOME' PATH=/usr/bin:/bin DOTFILES='$ROOT' DOTFILES_PROMPT_STDIN=1 TERM=xterm-256color bash -c \"source '$ROOT/lib/init.sh'; _dotfiles_init\""
    grep -q "Keep Me" "$HOME/.gitconfig.local"
}

@test "init rejects an e-mail without an at sign" {
    run bash -c "printf 'Jane Dev\nnot-an-email\n' | env -i HOME='$HOME' PATH=/usr/bin:/bin DOTFILES='$ROOT' DOTFILES_PROMPT_STDIN=1 TERM=xterm-256color bash -c \"source '$ROOT/lib/init.sh'; _dotfiles_init\""
    [ "$status" -ne 0 ]
    [ ! -f "$HOME/.gitconfig.local" ]
}
