#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export DOTFILES="$BATS_TEST_TMPDIR/dot" HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$DOTFILES/scripts/setup" "$DOTFILES/private/setup" "$HOME"
}

@test "setup registry merges private entries" {
    printf 'a.sh|auto|A\n' > "$DOTFILES/scripts/setup/registry.conf"
    printf 'b.sh|manual|B\n' > "$DOTFILES/private/setup/registry.conf"
    run bash -c "export DOTFILES='$DOTFILES'; source '$ROOT/lib/setup.sh'; _get_setup_scripts"
    [[ "$output" == *"a.sh|auto|A"* ]]
    [[ "$output" == *"b.sh|manual|B"* ]]
}

@test "a failing setup script does not stop the others" {
    printf '#!/usr/bin/env bash\nexit 1\n' > "$DOTFILES/scripts/setup/bad.sh"
    printf '#!/usr/bin/env bash\necho second-ran\n' > "$DOTFILES/scripts/setup/good.sh"
    printf 'bad.sh|auto|Bad\ngood.sh|auto|Good\n' > "$DOTFILES/scripts/setup/registry.conf"
    run bash -c "export DOTFILES='$DOTFILES'; source '$ROOT/lib/setup.sh'; _run_setup"
    [[ "$output" == *"second-ran"* ]]
    [[ "$output" == *"bad.sh"* ]]
}

@test "only auto scripts run by default and manual ones run by name" {
    printf '#!/usr/bin/env bash\necho manual-ran\n' > "$DOTFILES/scripts/setup/m.sh"
    printf 'm.sh|manual|Manual\n' > "$DOTFILES/scripts/setup/registry.conf"
    run bash -c "export DOTFILES='$DOTFILES'; source '$ROOT/lib/setup.sh'; _run_setup"
    [[ "$output" != *"manual-ran"* ]]
    run bash -c "export DOTFILES='$DOTFILES'; source '$ROOT/lib/setup.sh'; _setup_run_one m"
    [[ "$output" == *"manual-ran"* ]]
}

@test "dry-run prints the scripts and runs none" {
    printf '#!/usr/bin/env bash\necho should-not-run\n' > "$DOTFILES/scripts/setup/x.sh"
    printf 'x.sh|auto|X\n' > "$DOTFILES/scripts/setup/registry.conf"
    run bash -c "export DOTFILES='$DOTFILES' DOTFILES_DRY_RUN=1; source '$ROOT/lib/setup.sh'; _run_setup"
    [[ "$output" == *"x.sh"* ]]
    [[ "$output" != *"should-not-run"* ]]
}

@test "setup.sh holds no per-script data" {
    run grep -nE "fix-cedilla|gtk-dark|file-associations|podman-storage|tailscale" "$ROOT/lib/setup.sh"
    [ "$status" -ne 0 ]
}
