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

@test "status does not mention packages or profiles yet" {
    run grep -nE '_check_installed_packages|_check_profile' "$ROOT/lib/status.sh"
    [ "$status" -ne 0 ]
}
