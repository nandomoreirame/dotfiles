#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; R="$ROOT/bin/README.md"; }

@test "bin readme documents privileges and path" {
    grep -q "Privileges" "$R"
    grep -q "PATH" "$R"
    grep -qi "root" "$R"
    grep -qi "ssh" "$R"
}

@test "bin readme lists all eight helpers" {
    for n in sys-btrfs-backup sys-clean-cache clean-claude-sessions notify-open video-to-gif localsend-clip espanso-hotplug droidcam-ctl; do
        grep -q "^| \`$n\`" "$R"
    done
}

@test "bin readme has a security section for privileged and remote helpers" {
    grep -q "^## Security" "$R"
    # Names must appear in the Security section, not only elsewhere in the file.
    sec="$(awk '/^## Security/{flag=1;next} /^## /{flag=0} flag' "$R")"
    for n in sys-btrfs-backup sys-clean-cache clean-claude-sessions localsend-clip droidcam-ctl; do
        grep -q "$n" <<< "$sec"
    done
}

@test "the root readme links the helper table" {
    grep -q "bin/README.md" "$ROOT/README.md"
}

@test "the changelog records the helpers" {
    grep -qi "helper" "$ROOT/CHANGELOG.md"
}

@test "help prints usage and exits 0" {
    for n in sys/sys-btrfs-backup sys/sys-clean-cache utils/clean-claude-sessions; do
        run env -i HOME="$HOME" PATH="/usr/bin:/bin" bash "$ROOT/bin/$n" --help
        [ "$status" -eq 0 ]
        [[ "$output" == *"sage"* ]]
    done
}
