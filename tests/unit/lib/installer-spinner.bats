#!/usr/bin/env bats

# Every install, download and setup step runs through spin_run (lib/spinner.sh).

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME"
    : > "$LOG"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$DOTFILES_PRIVATE"
}

fn_body() { sed -n "/^$2() {/,/^}/p" "$ROOT/lib/$1"; }

@test "every package runner goes through spin_run" {
    for pair in pacman-packages.sh:_pacman_run aur-packages.sh:_aur_run flatpak-packages.sh:_flatpak_run \
        node-packages.sh:_node_run sh-apps.sh:_sh_run; do
        body="$(fn_body "${pair%%:*}" "${pair#*:}")"
        [ -n "$body" ]
        [[ "$body" == *"spin_run"* ]] || { echo "no spin_run in ${pair#*:}"; false; }
    done
}

@test "runners that call sudo ask for the password before the spinner" {
    [[ "$(fn_body pacman-packages.sh _pacman_run)" == *"spin_sudo_prime"* ]]
    [[ "$(fn_body aur-packages.sh _aur_run)" == *"spin_sudo_prime"* ]]
}

@test "pacman install with a terminal hides pacman output and names the package" {
    printf '#!/bin/sh\n[ "$1" = "-Q" ] && exit 1\necho noisy-pacman-output\nexit 0\n' > "$STUBS/pacman"
    printf '#!/bin/sh\nexec "$@"\n' > "$STUBS/sudo"
    chmod +x "$STUBS/pacman" "$STUBS/sudo"
    run --separate-stderr env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" \
        DOTFILES_PRIVATE="$DOTFILES_PRIVATE" TERM=xterm-256color DOTFILES_YES=1 DOTFILES_SPINNER=1 \
        bash -c "source '$ROOT/lib/pacman-packages.sh'; _pacman_packages demo-pkg"
    [ "$status" -eq 0 ]
    [[ "$stderr" == *"Installing demo-pkg"* ]]
    [[ "$output" != *"noisy-pacman-output"* ]]
}

@test "mise install runs through the spinner" {
    [[ "$(sed -n '/mise install/p' "$ROOT/lib/mise-packages.sh")" == *"spin_run"* ]]
}

@test "auto setup steps use the spinner and manual runs stay plain" {
    [[ "$(fn_body setup.sh _setup_exec)" == *"spin_run"* ]]
    [[ "$(fn_body setup.sh _setup_run_one)" != *"spin_run"* ]]
}

@test "the yay bootstrap only spins makepkg when it runs with --noconfirm" {
    body="$(fn_body install.sh _install_step_aur_helper)"
    [[ "$body" == *'spin_run "Cloning yay"'* ]]
    [[ "$body" == *'--noconfirm'* ]]
    [[ "$body" == *'spin_run "Building yay"'* ]]
}

@test "the oh-my-zsh download and installer run through the spinner" {
    [[ "$(cat "$ROOT/lib/sh-apps.sh")" == *'spin_run "Downloading oh-my-zsh installer"'* ]]
}

@test "webapp install downloads icons through the spinner" {
    run grep -cE 'spin_run "(Fetching favicon|Downloading icon)' "$ROOT/bin/utils/webapp"
    [ "$output" -eq 2 ]
}

@test "the editor theme installer registers extensions through the spinner" {
    grep -Fq 'spin_run "Installing Terminal Noir in $editor"' "$ROOT/scripts/themes/install-terminal-noir-editors"
}
