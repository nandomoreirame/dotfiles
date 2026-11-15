#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; N="$ROOT/configs/noctalia"; }

@test "bar uses built-in widgets only" {
    run grep -nE '^type = "[^"]*/' "$N/bar.toml"
    [ "$status" -ne 0 ]
}

@test "plugins.toml enables no plugin" {
    run python3 -I -c 'import sys,tomllib; d=tomllib.load(open(sys.argv[1],"rb")); sys.exit(0 if d["plugins"]["enabled"]==[] else 1)' "$N/plugins.toml"
    [ "$status" -eq 0 ]
}

@test "noctalia files carry no personal string" {
    run grep -rnE "nan""domoreira|avatar_path|/home/|Imagens" "$N"
    [ "$status" -ne 0 ]
}

@test "every noctalia toml file parses" {
    for f in config bar plugins user-templates; do
        python3 -I -c 'import sys,tomllib; tomllib.load(open(sys.argv[1],"rb"))' "$N/$f.toml"
    done
}

@test "the theme palette from the apps milestone is still present" {
    [ -f "$N/palettes/Terminal Noir.json" ]
}
