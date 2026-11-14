#!/usr/bin/env bats

# Unit tests for scripts/themes/build-terminal-noir-icons
#
# Run:
#   ./tests/run-tests unit/scripts/build-terminal-noir-icons.bats
#
# A fake Adwaita tree stands in for /usr/share/icons/Adwaita, using the same
# five blues the real folder SVGs use.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/scripts/themes/build-terminal-noir-icons"

setup() {
    TEST_DIR="$(temp_make)"
    SRC="$TEST_DIR/Adwaita"
    OUT="$TEST_DIR/Terminal-Noir"
    mkdir -p "$SRC/scalable/places"

    local svg='<svg><path fill="#438de6"/><path fill="#62a0ea"/><path fill="#a4caee"/><path fill="#afd4ff"/><path fill="#c0d5ea"/><path fill="#ffffff"/></svg>'
    local name
    for name in folder folder-documents folder-download user-home user-desktop user-bookmarks; do
        printf '%s\n' "$svg" > "$SRC/scalable/places/$name.svg"
    done
    printf '%s\n' '<svg><path fill="#62a0ea"/></svg>' > "$SRC/scalable/places/user-trash.svg"
    printf '%s\n' '<svg><path fill="#62a0ea"/></svg>' > "$SRC/scalable/places/network-server.svg"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "writes an index.theme that inherits Adwaita" {
    run "$SCRIPT" "$SRC" "$OUT"
    assert_success

    grep -Fqx 'Name=Terminal-Noir' "$OUT/index.theme"
    grep -Fqx 'Inherits=Adwaita,AdwaitaLegacy,hicolor' "$OUT/index.theme"
    grep -Fqx 'Directories=scalable/places' "$OUT/index.theme"
    grep -Fqx '[scalable/places]' "$OUT/index.theme"
}

@test "recolors folder and user-dir icons from blue to amber" {
    run "$SCRIPT" "$SRC" "$OUT"
    assert_success

    local f
    for f in folder folder-documents folder-download user-home user-desktop user-bookmarks; do
        [ -f "$OUT/scalable/places/$f.svg" ]
        ! grep -qiE '#(438de6|62a0ea|a4caee|afd4ff|c0d5ea)' "$OUT/scalable/places/$f.svg"
        grep -qi '#f5a623' "$OUT/scalable/places/$f.svg"
        grep -qi '#ffffff' "$OUT/scalable/places/$f.svg"
    done
}

@test "leaves icons that are not folders to Adwaita" {
    run "$SCRIPT" "$SRC" "$OUT"
    assert_success

    [ ! -e "$OUT/scalable/places/user-trash.svg" ]
    [ ! -e "$OUT/scalable/places/network-server.svg" ]
}

@test "a rebuild replaces stale icons" {
    mkdir -p "$OUT/scalable/places"
    echo stale > "$OUT/scalable/places/folder-gone.svg"

    run "$SCRIPT" "$SRC" "$OUT"
    assert_success

    [ ! -e "$OUT/scalable/places/folder-gone.svg" ]
}

@test "fails when the Adwaita source is missing" {
    run "$SCRIPT" "$TEST_DIR/nope" "$OUT"
    assert_failure
    [ ! -e "$OUT/index.theme" ]
}
