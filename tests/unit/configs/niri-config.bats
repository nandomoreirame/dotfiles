#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; C="$ROOT/configs/niri/config.kdl"; }

@test "niri config carries no absolute home paths" {
    # Personal binds live in private.kdl now; only absolute home paths stay out.
    run grep -nE "/home/" "$C" "$ROOT/configs/niri/monitor.kdl" "$ROOT/configs/niri/private.kdl"
    [ "$status" -ne 0 ]
}

@test "every bin/utils helper referenced in config.kdl exists in the public tree" {
    local ref base missing=0
    while IFS= read -r ref; do
        base="${ref##*/}"
        base="${base%% *}"
        base="${base%%\"*}"
        if [ ! -e "$ROOT/bin/utils/$base" ]; then
            echo "missing helper: $base (from $ref)" >&2
            missing=1
        fi
    done < <(grep -oE '~/.dotfiles/bin/utils/[a-z0-9_-]+' "$C" | sort -u)
    [ "$missing" -eq 0 ]
}

@test "niri config includes the monitor example and ends with the private hook" {
    grep -q '^include "monitor.kdl"' "$C"
    tail -n 3 "$C" | grep -q 'include "private.kdl"'
}

@test "monitor.kdl declares at least one output" {
    [ "$(grep -c '^output ' "$ROOT/configs/niri/monitor.kdl")" -ge 1 ]
}

@test "niri validates the config with the example files" {
    command -v niri > /dev/null || skip "niri is not installed"
    d="$BATS_TEST_TMPDIR/niri"; mkdir -p "$d"; cp "$ROOT"/configs/niri/*.kdl "$d/"
    run niri validate -c "$d/config.kdl"
    [ "$status" -eq 0 ]
}
