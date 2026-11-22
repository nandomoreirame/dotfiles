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

# ---- vicinae.sh: settings.json import and the user service ----

vic_stubs() {
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/vicinae"
    printf '#!/bin/sh\necho "systemctl $*" >> "%s"\ncase "$*" in *is-enabled*) exit "${VIC_ENABLED:-1}";; esac\nexit 0\n' "$LOG" > "$STUBS/systemctl"
    chmod +x "$STUBS/vicinae" "$STUBS/systemctl"
}

run_vic() { run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/vicinae.sh"; }

@test "vicinae is a no-op when vicinae is missing" {
    run env -i HOME="$HOME" PATH="$STUBS" /usr/bin/bash "$ROOT/scripts/setup/vicinae.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"vicinae not found"* ]]
    [ ! -e "$HOME/.config/vicinae/settings.json" ]
}

@test "vicinae creates settings.json importing dotfiles.json when missing" {
    vic_stubs
    run_vic
    [ "$status" -eq 0 ]
    run jq -r '.imports[0]' "$HOME/.config/vicinae/settings.json"
    [ "$output" = "dotfiles.json" ]
}

@test "vicinae leaves a settings.json that already imports dotfiles.json untouched" {
    vic_stubs
    mkdir -p "$HOME/.config/vicinae"
    printf '// GUI comment\n{\n  "imports": ["dotfiles.json"],\n  "font": {"normal": {"size": 12}}\n}\n' > "$HOME/.config/vicinae/settings.json"
    before="$(md5sum < "$HOME/.config/vicinae/settings.json")"
    run_vic
    [ "$status" -eq 0 ]
    [ "$(md5sum < "$HOME/.config/vicinae/settings.json")" = "$before" ]
}

@test "vicinae warns instead of rewriting a settings.json without the import" {
    vic_stubs
    mkdir -p "$HOME/.config/vicinae"
    printf '// GUI comment\n{\n  "font": {"normal": {"size": 12}}\n}\n' > "$HOME/.config/vicinae/settings.json"
    before="$(md5sum < "$HOME/.config/vicinae/settings.json")"
    run_vic
    [ "$status" -eq 0 ]
    [[ "$output" == *'"imports": ["dotfiles.json"]'* ]]
    [ "$(md5sum < "$HOME/.config/vicinae/settings.json")" = "$before" ]
}

@test "vicinae enables the user service" {
    vic_stubs
    run_vic
    grep -Fqx 'systemctl --user enable --now vicinae.service' "$LOG"
}

@test "the registry runs vicinae.sh during install" {
    grep -Fq 'vicinae.sh|auto|' "$ROOT/scripts/setup/registry.conf"
}

@test "vicinae leaves an already enabled service alone" {
    vic_stubs
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" VIC_ENABLED=0 bash "$ROOT/scripts/setup/vicinae.sh"
    [ "$status" -eq 0 ]
    run grep -q 'enable --now' "$LOG"
    [ "$status" -ne 0 ]
}

@test "file-associations keeps a MIME type that already has a default" {
    mkdir -p "$HOME/.local/share/applications"
    printf '[Desktop Entry]\nName=Calc\n' > "$HOME/.local/share/applications/libreoffice-calc.desktop"
    printf '#!/bin/sh\necho "xdg-mime $*" >> "%s"\n[ "$1" = "query" ] && [ "$3" = "text/csv" ] && echo other.desktop\nexit 0\n' "$LOG" > "$STUBS/xdg-mime"
    chmod +x "$STUBS/xdg-mime"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/file-associations.sh"
    [ "$status" -eq 0 ]
    run grep -q 'xdg-mime default libreoffice-calc.desktop text/csv' "$LOG"
    [ "$status" -ne 0 ]
    grep -q 'xdg-mime default libreoffice-calc.desktop application/vnd.ms-excel$' "$LOG"
}

@test "gtk-dark skips keys that already hold the dark value" {
    printf '#!/bin/sh\necho "gsettings $*" >> "%s"\n[ "$1" = "get" ] && [ "$3" = "color-scheme" ] && echo "\x27prefer-dark\x27"\nexit 0\n' "$LOG" > "$STUBS/gsettings"
    chmod +x "$STUBS/gsettings"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/gtk-dark.sh"
    [ "$status" -eq 0 ]
    run grep -q 'set org.gnome.desktop.interface color-scheme' "$LOG"
    [ "$status" -ne 0 ]
    grep -q 'set org.gnome.desktop.interface gtk-theme adw-gtk3-dark' "$LOG"
}

# libvirt.sh stubs. LV_ENABLED / LV_GROUPS / LV_NET drive the reported state.
lv_stubs() {
    printf '#!/bin/sh\nexit 0\n' > "$STUBS/libvirtd"
    printf '#!/bin/sh\necho "virsh $*" >> "%s"\ncase "$*" in *net-info*) printf "Name: default\\nActive: %%s\\nAutostart: %%s\\n" "${LV_NET_ACTIVE:-no}" "${LV_NET_AUTO:-no}";; esac\nexit 0\n' "$LOG" > "$STUBS/virsh"
    printf '#!/bin/sh\necho "systemctl $*" >> "%s"\ncase "$*" in *is-enabled*) exit "${LV_ENABLED:-1}";; esac\nexit 0\n' "$LOG" > "$STUBS/systemctl"
    printf '#!/bin/sh\necho "sudo $*" >> "%s"\nexec "$@"\n' "$LOG" > "$STUBS/sudo"
    printf '#!/bin/sh\necho "usermod $*" >> "%s"\n' "$LOG" > "$STUBS/usermod"
    printf '#!/bin/sh\n[ "$1" = "-nG" ] && { echo "${LV_GROUPS:-wheel}"; exit 0; }\n[ "$1" = "-un" ] && { echo tester; exit 0; }\nexit 0\n' > "$STUBS/id"
    chmod +x "$STUBS"/*
}

run_lv() { run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" USER=tester "$@" bash "$ROOT/scripts/setup/libvirt.sh"; }

@test "libvirt is a no-op when libvirt is not installed" {
    run env -i HOME="$HOME" PATH="$STUBS" USER=tester /usr/bin/bash "$ROOT/scripts/setup/libvirt.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"libvirt not installed"* ]]
}

@test "libvirt enables the daemon, adds the user and starts the default network" {
    lv_stubs
    run_lv
    [ "$status" -eq 0 ]
    grep -Fqx 'sudo systemctl enable --now libvirtd.service' "$LOG"
    grep -Fqx 'usermod -aG libvirt tester' "$LOG"
    grep -Fq 'virsh --connect qemu:///system net-autostart default' "$LOG"
    grep -Fq 'virsh --connect qemu:///system net-start default' "$LOG"
    [[ "$output" == *"Log out and back in"* ]]
}

@test "libvirt changes nothing when everything is already set up" {
    lv_stubs
    run_lv LV_ENABLED=0 LV_GROUPS="wheel libvirt" LV_NET_ACTIVE=yes LV_NET_AUTO=yes
    [ "$status" -eq 0 ]
    run grep -E 'enable --now|usermod|net-autostart|net-start' "$LOG"
    [ "$status" -ne 0 ]
}

@test "the registry runs libvirt.sh during install" {
    grep -Fq 'libvirt.sh|auto|' "$ROOT/scripts/setup/registry.conf"
}

# fa_stubs <current-default-for-inode/directory>: xdg-mime that reports it.
fa_stubs() {
    mkdir -p "$HOME/.local/share/applications"
    printf '[Desktop Entry]\nName=Luciole\n' > "$HOME/.local/share/applications/dev.noctalia.luciole.desktop"
    printf '#!/bin/sh\necho "xdg-mime $*" >> "%s"\n[ "$1" = "query" ] && [ "$3" = "inode/directory" ] && [ -n "%s" ] && echo "%s"\nexit 0\n' "$LOG" "$1" "$1" > "$STUBS/xdg-mime"
    chmod +x "$STUBS/xdg-mime"
}

@test "file-associations makes Luciole the folder handler when none is set" {
    fa_stubs ""
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/file-associations.sh"
    [ "$status" -eq 0 ]
    grep -Fqx 'xdg-mime default dev.noctalia.luciole.desktop inode/directory' "$LOG"
}

@test "file-associations replaces Nautilus as the folder handler" {
    fa_stubs "org.gnome.Nautilus.desktop"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/file-associations.sh"
    [ "$status" -eq 0 ]
    grep -Fqx 'xdg-mime default dev.noctalia.luciole.desktop inode/directory' "$LOG"
}

@test "file-associations keeps another folder handler the user chose" {
    fa_stubs "thunar.desktop"
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" bash "$ROOT/scripts/setup/file-associations.sh"
    [ "$status" -eq 0 ]
    run grep -F 'xdg-mime default dev.noctalia.luciole.desktop' "$LOG"
    [ "$status" -ne 0 ]
}

@test "the file manager is Luciole in the package list and the compositor binds" {
    grep -qw 'luciole-git' "$ROOT/packages/aur.list"
    grep -Fq '"Mod+Shift+F" = { action = "spawn luciole"' "$ROOT/configs/umbriel/base.toml"
    grep -Fq 'spawn "luciole"' "$ROOT/configs/niri/config.kdl"
    run grep -n 'nautilus' "$ROOT/configs/umbriel/base.toml" "$ROOT/configs/niri/config.kdl"
    [ "$status" -ne 0 ]
}
