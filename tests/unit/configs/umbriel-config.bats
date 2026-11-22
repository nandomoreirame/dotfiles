#!/usr/bin/env bats

# Umbriel compositor: config.toml is a thin entry point that includes base.toml
# (public) and then the optional private.toml from the private overlay.

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    U="$ROOT/configs/umbriel"
}

@test "config.toml includes base.toml before the optional private.toml" {
    run grep -Fx 'files = ["base.toml", "private.toml"]' "$U/config.toml"
    [ "$status" -eq 0 ]
    run grep -Fx '[include.optional]' "$U/config.toml"
    [ "$status" -eq 0 ]
}

@test "private.toml is not in the public tree" {
    [ ! -e "$U/private.toml" ]
}

@test "base.toml carries no personal binds, outputs or app ids" {
    _a="nando""moreira"
    run grep -nE "${_a}|obs-live|iPhone|gsr-toggle|daybar|gistbar|rdo-solo|devnull|quick-translate|live-chat|focus-mode|beaverhabits|raycast|whatsapp|grok|^\[output\." "$U/base.toml"
    [ "$status" -ne 0 ]
}

@test "every bin/utils helper referenced in base.toml exists in the public tree" {
    missing=""
    while read -r h; do
        [ -x "$ROOT/bin/utils/$h" ] || missing+="$h "
    done < <(grep -oE 'bin/utils/[A-Za-z0-9_-]+' "$U/base.toml" | sed 's|bin/utils/||' | sort -u)
    [ -z "$missing" ] || { echo "missing: $missing"; false; }
}

@test "links.conf links the umbriel files one by one so the overlay can add private.toml" {
    run grep -E '^configs/umbriel[ /]' "$ROOT/configs/links.conf"
    [[ "$output" == *"configs/umbriel/config.toml | .config/umbriel/config.toml"* ]]
    [[ "$output" == *"configs/umbriel/base.toml | .config/umbriel/base.toml"* ]]
    run grep -E '^configs/umbriel \|' "$ROOT/configs/links.conf"
    [ "$status" -ne 0 ]
}

@test "umbriel validates the public config without the overlay" {
    command -v umbriel >/dev/null 2>&1 || skip "umbriel not installed"
    mkdir -p "$BATS_TEST_TMPDIR/xdg/umbriel"
    cp "$U/config.toml" "$U/base.toml" "$BATS_TEST_TMPDIR/xdg/umbriel/"
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="/usr/bin:/bin" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/xdg" umbriel config validate
    [ "$status" -eq 0 ]
}

@test "every scratchpad hides when empty so a closed window does not leave its dim behind" {
    run python3 - "$U/base.toml" <<'PY'
import sys, tomllib
pads = tomllib.load(open(sys.argv[1], "rb")).get("scratchpad", [])
missing = [p["name"] for p in pads if p.get("hide_when_empty") is not True]
print(" ".join(missing))
sys.exit(1 if missing or not pads else 0)
PY
    [ "$status" -eq 0 ] || { echo "missing hide_when_empty: $output"; false; }
}
