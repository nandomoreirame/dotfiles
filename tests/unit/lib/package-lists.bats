#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export DOTFILES="$BATS_TEST_TMPDIR/dot"
    mkdir -p "$DOTFILES/packages" "$DOTFILES/private/packages"
    printf '# comment\n## core\nbat git\nbat\n\n## apps\nfoo\n' > "$DOTFILES/packages/pacman.list"
}

pl() { run bash -c "export DOTFILES='$DOTFILES'; source '$ROOT/lib/package-lists.sh'; $1"; }

@test "lists ignore comments and blanks and remove duplicates" {
    pl '_package_list pacman'
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | sort | tr '\n' ' ')" = "bat foo git " ]
}

@test "a group filters its names" {
    pl '_package_list pacman core'
    [ "$(printf '%s\n' "$output" | sort | tr '\n' ' ')" = "bat git " ]
}

@test "private list is appended" {
    printf 'secret-tool\n' > "$DOTFILES/private/packages/pacman.list"
    pl '_package_list pacman'
    [[ "$output" == *"secret-tool"* ]]
    pl '_package_list pacman private'
    [ "$output" = "secret-tool" ]
}

@test "missing private list is silent" {
    pl '_package_list pacman core'
    [[ "$output" != *"rror"* ]]
}

@test "an unknown kind fails with a message" {
    pl '_package_list nope'
    [ "$status" -ne 0 ]
    [[ "$output" == *"nope"* ]]
}

@test "public lists define the expected groups" {
    for g in core shell containers fonts desktop; do
        grep -q "^## $g\$" "$ROOT/packages/pacman.list"
    done
    grep -q '^# ' "$ROOT/packages/pacman.list"
}

@test "install code carries no personal data" {
    # LC_ALL=C.UTF-8 keeps UTF-8 bracket expressions from matching emoji bytes under bare C.
    local paths=("$ROOT/lib" "$ROOT/packages")
    [ -e "$ROOT/install.sh" ] && paths+=("$ROOT/install.sh")
    run env LC_ALL=C.UTF-8 grep -rnEi "discord|spotify|obsidian|cursor-bin|heroic|vivaldi|zen-browser|1password|antigravity|jan-bin|homelab|tailscale|nandomoreira" "${paths[@]}"
    [ "$status" -ne 0 ]
    run env LC_ALL=C.UTF-8 grep -rnE "[áàâãéêíóôõúç]|\b(não|erro|pacote|falha)\b" "$ROOT/lib" "$ROOT/packages"
    [ "$status" -ne 0 ]
}

@test "author baseline union matches the previous defaults" {
    [ -d "$ROOT/private/baseline" ] || skip "author-only check: needs private/baseline"
    export DOTFILES="$ROOT"
    for kind in pacman aur flatpak node; do
        want="$(tr ' ' '\n' < "$ROOT/private/baseline/$kind.txt" | sed '/^$/d' | sort -u)"
        got="$(bash -c "export DOTFILES='$ROOT'; source '$ROOT/lib/package-lists.sh'; _package_list $kind" | sort -u)"
        [ "$want" = "$got" ]
    done
}
