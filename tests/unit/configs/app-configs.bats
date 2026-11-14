#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

MIGRATED=(
  configs/.zshenv configs/.zshrc configs/.bashrc configs/.profile configs/.p10k.zsh configs/.gitconfig
  configs/.curlrc configs/.wgetrc configs/.prettierrc.json configs/.prettierignore
  configs/btop/btop.conf configs/fastfetch/config-dotfiles.jsonc configs/glow/glow.yml
  configs/lazygit/config.yml configs/starship.toml configs/mise/config.toml
  configs/git/ignore configs/git/attributes configs/git/message
)

@test "every migrated config is listed in links.conf" {
    local entry
    for f in "${MIGRATED[@]}"; do
        case "$f" in
            configs/lazygit/config.yml) entry="configs/lazygit" ;;
            configs/.*) entry="${f#configs/}" ;;
            *) entry="$f" ;;
        esac
        if [[ "$entry" == .* ]]; then
            grep -qxF "$entry" "$ROOT/configs/links.conf"
        else
            grep -qE "^${entry//./\\.}[[:space:]]*\\|" "$ROOT/configs/links.conf" || grep -qxF "$entry" "$ROOT/configs/links.conf"
        fi
    done
}

@test "verify passes on a scratch home" {
    export HOME="$BATS_TEST_TMPDIR/home"; mkdir -p "$HOME"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" links --all
    [ "$status" -eq 0 ]
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" bash "$ROOT/bin/dotfiles" --verify
    [ "$status" -eq 0 ]
}

@test "lazygit config starts no ai agent" {
    run grep -niE 'claude|codex|gemini|--dangerously|allowedTools' "$ROOT/configs/lazygit/config.yml"
    [ "$status" -ne 0 ]
}

@test "migrated files contain no personal data" {
    for f in "${MIGRATED[@]}"; do
        _a="nando""moreira"
        run grep -nEi '${_a}|@gmail|/home/[a-z]|marginalia|homelab|brain\b|192\.168\.|100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.' "$ROOT/$f"
        [ "$status" -ne 0 ]
        # .p10k.zsh is upstream-generated and ships box-drawing/emoji that trip
        # ugrep's Unicode character-class matching; skip the accent scan there.
        if [[ "$f" == configs/.p10k.zsh ]]; then
            continue
        fi
        run grep -nE "[áàâãéêíóôõúç]|\b(não|erro|arquivo)\b" "$ROOT/$f"
        [ "$status" -ne 0 ]
    done
}
