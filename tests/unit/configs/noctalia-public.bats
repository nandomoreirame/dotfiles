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

@test "config.toml has no dead podman-shutdown hooks" {
    ! grep -q 'podman-shutdown' "$N/config.toml"
}

@test "wallpaper directory is not the private wallpapers tree" {
    ! grep -qE 'directory = "~/.dotfiles/wallpapers"|directory = ".*/wallpapers"' "$N/config.toml"
}

@test "location does not hard-code a city with auto_locate false" {
    ! grep -qE 'address = "São Paulo"|address = "Sao Paulo"' "$N/config.toml"
    grep -q 'auto_locate = true' "$N/config.toml"
}

@test "user-templates.toml has no legacy config or templates sections" {
    ! grep -qE '^\[config\]|^\[templates\]' "$N/user-templates.toml"
}

@test "noctalia config validate is clean when the CLI is present" {
    command -v noctalia >/dev/null || skip "noctalia CLI not installed"
    run noctalia config validate "$N"
    [ "$status" -eq 0 ]
    [[ "$output" != *[Ww]arn* ]]
}
