#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

@test "private files are not in the public tree" {
    for p in configs/opencode configs/solaar configs/applications/input-remapper-gtk.desktop \
             configs/themes/terminal-noir/devnull-tui.json configs/espanso/match/base.yml \
             configs/espanso/match/personal.yml wallpapers; do
        [ ! -e "$ROOT/$p" ]
    done
}

@test "every app config is linked" {
    for k in ghostty tmux bat micro nvim gtk-3.0 gtk-4.0 chrome-flags electron-flags electron40-flags fcitx5 espanso \
             "Code/User/settings.json" "Code/User/keybindings.json" "Code/User/snippets"; do
        grep -q -- "$k" "$ROOT/configs/links.conf"
    done
}

@test "links and verify pass on a scratch home" {
    export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" links --all
    [ "$status" -eq 0 ]
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" --verify
    [ "$status" -eq 0 ]
    [ -L "$HOME/.config/ghostty/config" ]
    [ -L "$HOME/.config/nvim" ]
}

@test "the author name appears only in allowlisted credit lines" {
    local handle
    handle="$(printf '%s' "nando""moreira")"
    grep -q '^credit:' "$ROOT/scripts/public-check.allow"
    # Word boundaries keep the GitHub user <handle>me out of this scan.
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        file="${hit%%:*}"
        rest="${hit#*:}"
        line="${rest#*:}"
        grep -Fxq "credit:${file}:${line}" "$ROOT/scripts/public-check.allow"
    done < <(grep -rIn -- "$handle" \
        "$ROOT/configs" \
        "$ROOT/scripts/themes" \
        "$ROOT/README.md" \
        "$ROOT/CONTRIBUTING.md" 2>/dev/null \
        | grep -E "\\b${handle}\\b" \
        | grep -v 'nandomoreirame' \
        | sed "s|^$ROOT/||" || true)
}

@test "espanso snippets hold no personal data" {
    run grep -rnE "@gmail|[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}|\+55|/home/[a-z]" "$ROOT/configs/espanso"
    [ "$status" -ne 0 ]
}
