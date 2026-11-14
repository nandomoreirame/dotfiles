#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; R="$ROOT/README.md"; }

@test "readme documents profiles" {
    for k in "dotfiles profile" "git-personal.conf" "gcloud" "gitconfig.local"; do grep -q -- "$k" "$R"; done
}

@test "readme documents the hooks and their global effect" {
    grep -q "dotfiles hooks enable" "$R"
    grep -qi "every repository" "$R"
    grep -q "core.hooksPath" "$R"
    grep -qi "off by default\|disabled by default\|opt-in" "$R"
    grep -q "hooks disable" "$R"
}

@test "readme explains what the strip hook removes" {
    grep -qi "co-authored-by" "$R"
}

@test "profiles and hooks carry no personal data" {
    run grep -rnEi "nandomoreira|fernando|gmail\.com|homelab|tailscale" "$ROOT/lib/profiles.sh" "$ROOT/lib/profiles" "$ROOT/lib/hooks.sh" "$ROOT/profiles" "$ROOT/git-hooks" "$ROOT/bin/profile" "$ROOT/bin/git"
    [ "$status" -ne 0 ]
}

@test "the changelog records profiles and hooks" {
    grep -qi "profile" "$ROOT/CHANGELOG.md"
    grep -qi "hook" "$ROOT/CHANGELOG.md"
}
