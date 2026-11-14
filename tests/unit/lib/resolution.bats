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
    local module
    for module in output environments validation functions prompt links status help cli-parser private; do
        run env -i HOME="$DECOY" PATH=/usr/bin:/bin TERM=xterm-256color bash -ec \
            "source '$ROOT/lib/$module.sh'; printf '%s\\n' \"\$DOTFILES\""
        [ "$status" -eq 0 ]
        [[ "$output" != *DECOY-LOADED* ]]
        [ "$output" = "$ROOT" ]
    done
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
    local config
    for config in "$ROOT/.github/workflows/ci.yml" "$ROOT/scripts/simulate-clean-clone"; do
        grep -Fq 'shellcheck -x scripts/public-check scripts/simulate-clean-clone lib/*.sh tests/run-tests' "$config"
        grep -Fq 'bins=(bin/*/* lib/*/*.sh)' "$config"
        grep -Fq 'bins+=(bin/dotfiles)' "$config"
        grep -Fq 'shellcheck -x "${bins[@]}"' "$config"
    done
}
