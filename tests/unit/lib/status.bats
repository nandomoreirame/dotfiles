#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export DOTFILES="$BATS_TEST_TMPDIR/dot" HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES_PRIVATE="$DOTFILES/private"
    mkdir -p "$DOTFILES/configs/x" "$DOTFILES/private/y" "$HOME"
    echo a > "$DOTFILES/configs/x/c"; echo b > "$DOTFILES/private/y/d"; echo f > "$DOTFILES/configs/.rc"
    printf '[files]\n.rc\n[paths]\nconfigs/x/c | .config/x/c |\n' > "$DOTFILES/configs/links.conf"
    printf '[paths]\nprivate/y/d | .config/y/d |\n' > "$DOTFILES/private/links.conf"
}

sh_run() { run bash -c "source '$ROOT/lib/links.sh'; source '$ROOT/lib/status.sh'; $1"; }

@test "verify passes when every configured link exists" {
    bash -c "source '$ROOT/lib/links.sh'; _link_files; _link_paths" >/dev/null
    sh_run "_verify"
    [ "$status" -eq 0 ]
}

@test "verify fails and names a missing link" {
    sh_run "_verify"
    [ "$status" -ne 0 ]
    [[ "$output" == *".config/x/c"* ]]
}

@test "verify reports a link that points elsewhere" {
    bash -c "source '$ROOT/lib/links.sh'; _link_files; _link_paths" >/dev/null
    rm "$HOME/.config/x/c"; ln -s /srv/example/elsewhere "$HOME/.config/x/c"
    sh_run "_verify"
    [ "$status" -ne 0 ]
}

@test "verify checks the private links too" {
    bash -c "source '$ROOT/lib/links.sh'; _link_files; _link_paths" >/dev/null
    rm "$HOME/.config/y/d"
    sh_run "_verify"
    [ "$status" -ne 0 ]
    [[ "$output" == *".config/y/d"* ]]
}

@test "expected links come from links.conf" {
    bash -c "source '$ROOT/lib/links.sh'; _create_links all" >/dev/null
    sh_run "_verify"
    [ "$status" -eq 0 ]
    echo new > "$DOTFILES/configs/added"
    printf 'configs/added | .config/added |\n' >> "$DOTFILES/configs/links.conf"
    sh_run "_verify"
    [ "$status" -eq 1 ]
    [[ "$output" == *'.config/added'* ]]
    bash -c "source '$ROOT/lib/links.sh'; _create_links all" >/dev/null
    sh_run "_verify"
    [ "$status" -eq 0 ]
}

@test "status prints sections for links and PATH and does not fail on a healthy tree" {
    bash -c "source '$ROOT/lib/links.sh'; _link_files; _link_paths" >/dev/null
    sh_run "_status"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Status"* ]]
}

@test "status reports packages from the lists" {
    mkdir -p "$DOTFILES/packages"
    printf '## core\nbat\n' > "$DOTFILES/packages/pacman.list"
    STUBS="$BATS_TEST_TMPDIR/stubs"; mkdir -p "$STUBS"
    printf '#!/bin/sh\n[ "$1" = "-Q" ] && [ "$2" = "bat" ] && exit 0\nexit 1\n' > "$STUBS/pacman"
    chmod +x "$STUBS/pacman"
    bash -c "source '$ROOT/lib/links.sh'; _link_files; _link_paths" >/dev/null
    run env -i HOME="$HOME" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES/private" PATH="$STUBS:/usr/bin:/bin" TERM=xterm-256color \
        bash -c "source '$ROOT/lib/status.sh'; _check_installed_packages"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok: package bat"* ]]
}

@test "status reports the active identity profile" {
    mkdir -p "$DOTFILES/profiles/linux-arch" "$DOTFILES/lib" "$DOTFILES/bin"
    cp -r "$ROOT/lib/." "$DOTFILES/lib/"
    printf 'GIT_NAME="Jane Dev"\nGIT_EMAIL="jane@example.com"\n' \
        > "$DOTFILES/profiles/linux-arch/git-personal.conf"
    printf 'git-personal.conf\n' > "$DOTFILES/profiles/.current-git"
    bash -c "source '$ROOT/lib/links.sh'; _link_files; _link_paths" >/dev/null
    run env -i HOME="$HOME" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES/private" \
        PATH="$DOTFILES/bin:/usr/bin:/bin" TERM=xterm-256color \
        bash -c "source '$ROOT/lib/status.sh'; _check_profile"
    [ "$status" -eq 0 ]
    [[ "$output" == *"personal"* ]]
}

@test "status fails and names a bin directory missing from PATH" {
    mkdir -p "$DOTFILES/bin/sys"
    run env -i HOME="$HOME" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES/private" PATH="/usr/bin:/bin" TERM=xterm-256color \
        bash -c "source '$ROOT/lib/links.sh'; source '$ROOT/lib/status.sh'; _create_links all >/dev/null; _status"
    [ "$status" -ne 0 ]
    grep -Fxq "Missing PATH entry: $DOTFILES/bin" <<< "$output"
    grep -Fxq "Missing PATH entry: $DOTFILES/bin/sys" <<< "$output"
}

@test "status passes when the bin directories are on PATH" {
    mkdir -p "$DOTFILES/bin/sys"
    run env -i HOME="$HOME" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES/private" PATH="$DOTFILES/bin:$DOTFILES/bin/sys:/usr/bin:/bin" TERM=xterm-256color \
        bash -c "source '$ROOT/lib/links.sh'; source '$ROOT/lib/status.sh'; _create_links all >/dev/null; _status"
    [ "$status" -eq 0 ]
    grep -Fxq "ok: PATH contains $DOTFILES/bin" <<< "$output"
    grep -Fxq "ok: PATH contains $DOTFILES/bin/sys" <<< "$output"
}
