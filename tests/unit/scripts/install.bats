#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    FAKE="$BATS_TEST_TMPDIR/bin"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$FAKE"
    for c in pacman sudo yay git makepkg flatpak npm curl systemctl; do
        printf '#!/bin/sh\necho "%s $*" >> "%s"\nexit 0\n' "$c" "$LOG" > "$FAKE/$c"
        chmod +x "$FAKE/$c"
    done
    OSR="$BATS_TEST_TMPDIR/os-release"
    printf 'ID=arch\n' > "$OSR"
    : > "$LOG"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$DOTFILES_PRIVATE"
}

run_install_stdin() {
    local in="$1"
    shift
    run bash -c "printf '%s' \"\$1\" | env -i HOME='$HOME' PATH='$FAKE:/usr/bin:/bin' TERM=xterm-256color DOTFILES='$ROOT' DOTFILES_PRIVATE='$DOTFILES_PRIVATE' DOTFILES_OS_RELEASE_FILE='$OSR' DOTFILES_PROMPT_STDIN=1 bash '$ROOT/install.sh' $ARGS" _ "$in"
}

run_install() {
    run env -i HOME="$HOME" PATH="$FAKE:/usr/bin:/bin" DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" DOTFILES_OS_RELEASE_FILE="$OSR" TERM=xterm-256color "$@" bash "$ROOT/install.sh" $ARGS
}

@test "dry-run changes nothing and calls no sudo" {
    ARGS="--dry-run --yes" run_install
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    ! grep -q "^sudo" "$LOG"
    [ -z "$(ls -A "$HOME")" ]
}

@test "install refuses a non-Arch system" {
    printf 'ID=ubuntu\n' > "$OSR"
    ARGS="--dry-run --yes" run_install
    [ "$status" -ne 0 ]
    [[ "$output" == *"Arch"* ]]
}

@test "install prints every step in order" {
    ARGS="--dry-run --yes" run_install
    last=0
    for s in prerequisites "aur helper" packages fonts runtimes links setup; do
        n="$(printf '%s\n' "$output" | grep -n "$s" | head -1 | cut -d: -f1)"
        [ -n "$n" ]
        [ "$n" -gt "$last" ]
        last="$n"
    done
}

@test "a failing step is reported and the rest continue" {
    ARGS="--dry-run --yes" run_install DOTFILES_FAIL_STEP=fonts
    [ "$status" -ne 0 ]
    [[ "$output" == *"fonts failed"* ]]
    [[ "$output" == *"links"* ]]
}

@test "no-remote skips the downloaded installer" {
    ARGS="--dry-run --yes --no-remote" run_install
    [[ "$output" != *"ohmyzsh"*"download"* ]]
}

@test "a group limits the package step" {
    ARGS="--dry-run --yes --group fonts" run_install
    [[ "$output" == *"ttf-meslo-nerd"* ]]
    # Package selection must not pull container packages when fonts is chosen.
    pkg_line="$(printf '%s\n' "$output" | grep 'Selected pacman packages:' | head -1)"
    [[ "$pkg_line" == *"ttf-meslo-nerd"* ]]
    [[ "$pkg_line" != *"podman"* ]]
}

@test "without yes every step asks and a refusal skips it" {
    ARGS="--dry-run" run_install_stdin $'y\nn\ny\ny\ny\ny\ny\ny\n'
    [[ "$output" == *"aur helper skipped"* ]]
    [[ "$output" == *"packages"* ]]
}

@test "yes accepts every step without reading stdin" {
    ARGS="--dry-run --yes" run_install
    [ "$status" -eq 0 ]
    [[ "$output" != *"skipped"* ]]
}

@test "the package step asks for a group when none is given" {
    ARGS="--dry-run" run_install_stdin $'y\ny\ny\n'
    [[ "$output" == *"group"* ]]
}

@test "install never pipes a download into a shell" {
    run grep -nE "curl[^|]*\|\s*(ba)?sh|wget[^|]*\|\s*(ba)?sh" "$ROOT/install.sh" "$ROOT/lib/install.sh"
    [ "$status" -ne 0 ]
}

@test "install prints the next steps" {
    ARGS="--dry-run --yes" run_install
    [[ "$output" == *"dotfiles init"* ]]
    [[ "$output" == *"dotfiles doctor"* ]]
}

@test "remote table pins yay to a commit" {
    grep -E '^yay\|https://aur\.archlinux\.org/yay\.git\|[0-9a-f]{40}$' "$ROOT/scripts/remote-installers.conf"
}

@test "aur helper dry-run mentions pinned yay commit and does not clone" {
    rm -f "$FAKE/yay" "$FAKE/paru"
    pin="$(awk -F'|' '/^yay\|/ { print $3; exit }' "$ROOT/scripts/remote-installers.conf")"
    [ -n "$pin" ]
    # PATH is FAKE only so a system yay/paru cannot satisfy the helper check.
    run env -i HOME="$HOME" PATH="$FAKE" DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" \
        DOTFILES_DRY_RUN=1 DOTFILES_YES=1 DOTFILES_IS_ARCH=true TERM=xterm-256color \
        /usr/bin/bash -c "source '$ROOT/lib/install.sh'; _install_step_aur_helper"
    [ "$status" -eq 0 ]
    [[ "$output" == *"$pin"* ]]
    ! grep -q "git clone" "$LOG"
}

@test "install and sh-apps do not leave RETURN traps" {
    run grep -nE 'trap .* RETURN' "$ROOT/lib/install.sh" "$ROOT/lib/sh-apps.sh"
    [ "$status" -ne 0 ]
}

run_prereq() {
    run env -i HOME="$HOME" PATH="$FAKE:/usr/bin:/bin" DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" DOTFILES_IS_ARCH=true TERM=xterm-256color \
        bash -c "source '$ROOT/lib/install.sh'; _install_step_prerequisites"
}

@test "prerequisites skip pacman when base-devel git and curl are installed" {
    run_prereq
    [ "$status" -eq 0 ]
    run grep -q "pacman -S" "$LOG"
    [ "$status" -ne 0 ]
}

@test "prerequisites upgrade and install only the missing packages" {
    printf '#!/bin/sh\necho "pacman $*" >> "%s"\n[ "$1" = "-Q" ] && [ "$3" = "base-devel" ] && exit 1\n[ "$1" = "-Q" ] && exit 0\nexit 0\n' "$LOG" > "$FAKE/pacman"
    printf '#!/bin/sh\necho "sudo $*" >> "%s"\nexec "$@"\n' "$LOG" > "$FAKE/sudo"
    run_prereq
    [ "$status" -eq 0 ]
    grep -q -- "pacman -Syu --noconfirm --needed base-devel$" "$LOG"
}

# Sources lib/install.sh with every package kind stubbed, then runs $PCMD.
run_steps() {
    run env -i HOME="$HOME" PATH="$FAKE:/usr/bin:/bin" DOTFILES="$ROOT" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" DOTFILES_IS_ARCH=true DOTFILES_YES=1 TERM=xterm-256color \
        bash -c "source '$ROOT/lib/install.sh'
            _apps_install_pacman() { echo CALLED-pacman; }
            _apps_install_aur() { echo CALLED-aur; _failure_record AUR broken-pkg; return 1; }
            _apps_install_flatpak() { echo CALLED-flatpak; }
            _apps_install_node() { echo CALLED-node; }
            _apps_install_sh() { echo CALLED-sh; }
            $PCMD"
}

@test "the packages step keeps going after one manager fails" {
    PCMD='_install_step_packages; echo "RC=$?"'
    run_steps
    for k in pacman aur flatpak node sh; do
        [[ "$output" == *"CALLED-$k"* ]] || { echo "skipped: $k"; false; }
    done
    [[ "$output" == *"RC=1"* ]]
}

@test "the install summary names the failed steps and packages" {
    PCMD='_install_step packages _install_step_packages; _install_report; echo "RC=$?"'
    run_steps
    [[ "$output" == *"Failed steps: packages"* ]]
    [[ "$output" == *"AUR: broken-pkg"* ]]
    [[ "$output" == *"RC=1"* ]]
}

@test "the install summary reports success when nothing failed" {
    PCMD='_install_report; echo "RC=$?"'
    run_steps
    [[ "$output" == *"Install finished"* ]]
    [[ "$output" == *"RC=0"* ]]
}
