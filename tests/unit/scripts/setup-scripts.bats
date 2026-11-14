#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME"
    : > "$LOG"
}

@test "fix-cedilla writes XCompose when Compose data exists" {
    [ -d /usr/share/X11/locale ] || skip "no X11 locale compose data"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" LANG=en_US.UTF-8 bash "$ROOT/scripts/setup/fix-cedilla.sh"
    [ "$status" -eq 0 ]
    if [ -f "$HOME/.XCompose" ]; then
        run env -i HOME="$HOME" PATH="/usr/bin:/bin" LANG=en_US.UTF-8 bash "$ROOT/scripts/setup/fix-cedilla.sh"
        [ "$status" -eq 0 ]
        [[ "$output" == *"already configured"* ]]
    fi
}

@test "fix-cedilla keeps the first ORIGINAL across reruns" {
    compose_root="$BATS_TEST_TMPDIR/compose"
    mkdir -p "$compose_root/en_US.UTF-8"
    printf 'en_US.UTF-8/Compose: en_US.UTF-8\n' > "$compose_root/compose.dir"
    # U+0107 (ć) in UTF-8 so the sed rewrite produces a distinct file.
    printf 'key <c> : "\xc4\x87" marker-v1\n' > "$compose_root/en_US.UTF-8/Compose"
    printf 'user-original\n' > "$HOME/.XCompose"

    run env -i HOME="$HOME" PATH="/usr/bin:/bin" LANG=en_US.UTF-8 \
        DOTFILES_COMPOSE_DIR="$compose_root" bash "$ROOT/scripts/setup/fix-cedilla.sh"
    [ "$status" -eq 0 ]
    [ -f "$HOME/.XCompose.ORIGINAL" ]
    [ "$(cat "$HOME/.XCompose.ORIGINAL")" = "user-original" ]
    grep -q 'marker-v1' "$HOME/.XCompose"

    printf 'key <c> : "\xc4\x87" marker-v2\n' > "$compose_root/en_US.UTF-8/Compose"
    run env -i HOME="$HOME" PATH="/usr/bin:/bin" LANG=en_US.UTF-8 \
        DOTFILES_COMPOSE_DIR="$compose_root" bash "$ROOT/scripts/setup/fix-cedilla.sh"
    [ "$status" -eq 0 ]
    [ "$(cat "$HOME/.XCompose.ORIGINAL")" = "user-original" ]
    grep -q 'marker-v2' "$HOME/.XCompose"
}

@test "gtk-dark calls gsettings with dark values" {
    printf '#!/bin/sh\necho "gsettings $*" >> "%s"\nexit 0\n' "$LOG" > "$STUBS/gsettings"
    chmod +x "$STUBS/gsettings"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/gtk-dark.sh"
    [ "$status" -eq 0 ]
    grep -q 'color-scheme prefer-dark' "$LOG"
    grep -q 'gtk-theme adw-gtk3-dark' "$LOG"
}

@test "gtk-dark is a no-op when gsettings is missing" {
    run env -i HOME="$HOME" PATH="$STUBS" /usr/bin/bash "$ROOT/scripts/setup/gtk-dark.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"gsettings not found"* ]]
}

@test "file-associations calls xdg-mime when handler exists" {
    mkdir -p "$HOME/.local/share/applications"
    printf '[Desktop Entry]\nName=Calc\n' > "$HOME/.local/share/applications/libreoffice-calc.desktop"
    printf '#!/bin/sh\necho "xdg-mime $*" >> "%s"\nexit 0\n' "$LOG" > "$STUBS/xdg-mime"
    chmod +x "$STUBS/xdg-mime"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/file-associations.sh"
    [ "$status" -eq 0 ]
    grep -q 'xdg-mime default libreoffice-calc.desktop' "$LOG"
}

@test "file-associations skips when xdg-mime is missing" {
    run env -i HOME="$HOME" PATH="$STUBS" /usr/bin/bash "$ROOT/scripts/setup/file-associations.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"xdg-mime not found"* ]]
}

@test "podman-storage skips when podman is missing" {
    run env -i HOME="$HOME" PATH="$STUBS" /usr/bin/bash "$ROOT/scripts/setup/podman-storage.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"podman not installed"* ]]
}

@test "podman-storage writes config on btrfs when tools exist" {
    printf '#!/bin/sh\necho "podman"\n' > "$STUBS/podman"
    printf '#!/bin/sh\necho btrfs\n' > "$STUBS/findmnt"
    chmod +x "$STUBS/podman" "$STUBS/findmnt"
    # Pretend fuse-overlayfs exists by linking a stub into a fake usr path? Script checks /usr/bin/fuse-overlayfs.
    [ -x /usr/bin/fuse-overlayfs ] || skip "fuse-overlayfs not installed"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" XDG_CONFIG_HOME="$HOME/.config" bash "$ROOT/scripts/setup/podman-storage.sh"
    [ "$status" -eq 0 ]
    [ -f "$HOME/.config/containers/storage.conf" ]
    grep -q 'fuse-overlayfs' "$HOME/.config/containers/storage.conf"
    # Second run is a no-op.
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" XDG_CONFIG_HOME="$HOME/.config" bash "$ROOT/scripts/setup/podman-storage.sh"
    [[ "$output" == *"already configured"* ]]
}

@test "setup scripts carry no Portuguese or personal data" {
    _a="nando""moreira"
    run env LC_ALL=C.UTF-8 grep -rnE "[áàâãéêíóôõúç]|\b(não|erro|pacote|falha)\b|${_a}|discord|spotify" "$ROOT/scripts/setup"
    [ "$status" -ne 0 ]
}
