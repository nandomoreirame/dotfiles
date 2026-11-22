#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; N="$ROOT/configs/noctalia"; }

@test "every plugin widget in the bar has its plugin enabled" {
    run python3 -I -c '
import sys, tomllib
bar = tomllib.load(open(sys.argv[1], "rb"))
enabled = set(tomllib.load(open(sys.argv[2], "rb"))["plugins"]["enabled"])
missing = sorted({w["type"].split(":")[0] for w in bar.get("widget", {}).values()
                  if isinstance(w, dict) and "/" in w.get("type", "")} - enabled)
print(" ".join(missing)); sys.exit(1 if missing else 0)' "$N/bar.toml" "$N/plugins.toml"
    [ "$status" -eq 0 ] || { echo "not enabled: $output"; false; }
}

@test "noctalia files carry no absolute home path" {
    run grep -rnE "/home/" "$N"
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

@test "config.toml hooks call helpers that exist in the clone or its overlay" {
    local ref path missing=0
    while IFS= read -r ref; do
        path="$ROOT/${ref#\~/.dotfiles/}"
        case "$ref" in *"/.dotfiles/private/"*) [ -d "$ROOT/private" ] || continue ;; esac
        [ -x "$path" ] || { echo "missing hook helper: $ref"; missing=1; }
    done < <(grep -oE '~/\.dotfiles/[A-Za-z0-9/_-]+' "$N/config.toml" | sort -u)
    [ "$missing" -eq 0 ]
}

@test "wallpaper directory is not inside the dotfiles tree" {
    run grep -nE 'directory = "~/\.dotfiles/' "$N/config.toml"
    [ "$status" -ne 0 ]
}

@test "user-templates.toml has no legacy config or templates sections" {
    ! grep -qE '^\[config\]|^\[templates\]' "$N/user-templates.toml"
}

@test "noctalia config validate is clean when the CLI is present" {
    command -v noctalia >/dev/null || skip "noctalia CLI not installed"
    run noctalia config validate "$N"
    [ "$status" -eq 0 ]
    # Judge the repo files only: ~/.local/state/noctalia/settings.toml is machine state.
    run grep -i warn <<<"$(grep -v '/.local/state/' <<<"$output")"
    [ "$status" -ne 0 ] || { echo "$output"; false; }
}
