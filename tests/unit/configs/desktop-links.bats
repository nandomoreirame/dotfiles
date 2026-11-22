#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    H="$BATS_TEST_TMPDIR/home"; P="$BATS_TEST_TMPDIR/private"; mkdir -p "$H" "$P/configs/niri" "$P/configs/noctalia"
}

d() { env -i HOME="$H" PATH="/usr/bin:/bin" TERM=xterm-256color DOTFILES="$ROOT" DOTFILES_PRIVATE="$P" DOTFILES_YES=1 bash "$ROOT/bin/dotfiles" "$@"; }

@test "desktop configs are linked and verified" {
    run d links create
    [ "$status" -eq 0 ]
    [ -L "$H/.config/niri/config.kdl" ]
    [ -L "$H/.config/noctalia/bar.toml" ]
    run d links verify
    [ "$status" -eq 0 ]
}

@test "private links replace the niri and bar files" {
    echo '// mine' > "$P/configs/niri/private.kdl"; echo '# mine' > "$P/configs/noctalia/bar.toml"
    printf '[paths]\nprivate/configs/niri/private.kdl | .config/niri/private.kdl |\nprivate/configs/noctalia/bar.toml | .config/noctalia/bar.toml |\n' > "$P/links.conf"
    run d links create
    [ "$status" -eq 0 ]
    [ "$(readlink "$H/.config/niri/private.kdl")" = "$P/configs/niri/private.kdl" ]
    [ "$(readlink "$H/.config/noctalia/bar.toml")" = "$P/configs/noctalia/bar.toml" ]
    run d links verify
    [ "$status" -eq 0 ]
}

@test "private hardware helpers are not in the public tree" {
    for f in niri-hdmi-automode audio-jack-autoswitch rdo-solo rdo-solo-live rdo-solo-state rdo-solo-toggle; do
        [ ! -e "$ROOT/bin/utils/$f" ]
    done
    [ ! -e "$ROOT/tests/unit/configs/noctalia-webappbar.bats" ]
}

@test "desktop files are free of personal strings" {
    run grep -rnE "nan""domoreira|/home/[a-z]" "$ROOT/configs/niri" "$ROOT/configs/noctalia/config.toml" "$ROOT/configs/noctalia/bar.toml" "$ROOT/configs/noctalia/plugins.toml" "$ROOT/bin/utils"
    [ "$status" -ne 0 ]
}

@test "the public check passes on the desktop files" {
    run bash "$ROOT/scripts/public-check" "$ROOT"
    [ "$status" -eq 0 ]
}
