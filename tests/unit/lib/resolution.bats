#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    DECOY="$BATS_TEST_TMPDIR/home"
    mkdir -p "$DECOY/.dotfiles/lib"
    for f in output.sh environments.sh validation.sh functions.sh prompt.sh links.sh status.sh help.sh cli-parser.sh; do
        printf 'echo DECOY-LOADED %s >&2\nexit 99\n' "$f" > "$DECOY/.dotfiles/lib/$f"
    done
}

@test "modules ignore a decoy home dotfiles" {
    run env -i HOME="$DECOY" PATH="/usr/bin:/bin" TERM=xterm-256color bash -ec "source '$ROOT/lib/environments.sh'; declare -F e_success >/dev/null || source '$ROOT/lib/output.sh'; echo \"\$DOTFILES\""
    [ "$status" -eq 0 ]
    [[ "$output" != *DECOY-LOADED* ]]
    [[ "$output" == *"$ROOT"* ]]
}

@test "DOTFILES defaults to the clone and can be overridden" {
    run env -i HOME="$DECOY" PATH="/usr/bin:/bin" bash -ec "source '$ROOT/lib/environments.sh'; echo \"\$DOTFILES\""
    [ "$output" = "$ROOT" ]
    run env -i HOME="$DECOY" PATH="/usr/bin:/bin" DOTFILES=/srv/example/dot bash -ec "source '$ROOT/lib/environments.sh'; echo \"\$DOTFILES\""
    [ "$output" = "/srv/example/dot" ]
}

@test "no file hard-codes the home dotfiles path" {
    run grep -rnE 'HOME/\.dotfiles|~/\.dotfiles' "$ROOT/lib" "$ROOT/bin"
    [ "$status" -ne 0 ]
}

@test "ci lints bin and lib" {
    grep -q "lib/" "$ROOT/.github/workflows/ci.yml"
    grep -q "bin/" "$ROOT/.github/workflows/ci.yml"
    grep -q "lib/" "$ROOT/scripts/simulate-clean-clone"
}
