#!/usr/bin/env bats

# Generated Terminal Noir themes stay in sync with their sources:
#   configs/noctalia/palettes/Terminal Noir.json
#   configs/themes/terminal-noir/syntax.json

load '../../bats/helpers/setup'

BUILD="$PROJECT_ROOT/scripts/themes/build-terminal-noir"
PALETTE="$PROJECT_ROOT/configs/noctalia/palettes/Terminal Noir.json"
SYNTAX="$PROJECT_ROOT/configs/themes/terminal-noir/syntax.json"
VSCODE_DIR="$PROJECT_ROOT/configs/vscode/terminal-noir"
VSCODE_THEME="$VSCODE_DIR/themes/terminal-noir-color-theme.json"
BAT_THEME="$PROJECT_ROOT/configs/bat/themes/Terminal Noir.tmTheme"
MICRO_THEME="$PROJECT_ROOT/configs/micro/colorschemes/terminal-noir.micro"
ROOT="$PROJECT_ROOT"

GENERATED=(
    "configs/vscode/terminal-noir/package.json"
    "configs/vscode/terminal-noir/themes/terminal-noir-color-theme.json"
    "configs/bat/themes/Terminal Noir.tmTheme"
    "configs/ghostty/themes/terminal-noir-dark"
    "configs/ghostty/themes/terminal-noir-light"
    "configs/micro/colorschemes/terminal-noir.micro"
)

setup() {
    TEST_DIR="$(temp_make)"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "committed themes match a fresh build" {
    run "$BUILD" "$TEST_DIR"
    assert_success

    local f
    for f in "${GENERATED[@]}"; do
        [ -f "$TEST_DIR/$f" ]
        cmp -s "$TEST_DIR/$f" "$PROJECT_ROOT/$f" || {
            echo "out of date: $f (run scripts/themes/build-terminal-noir)"
            return 1
        }
    done
}

@test "committed theme outputs match a fresh build" {
    out="$BATS_TEST_TMPDIR/out"
    mkdir -p "$out"
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="/usr/bin:/bin" DOTFILES="$ROOT" bash "$ROOT/scripts/themes/build-terminal-noir" --out "$out"
    [ "$status" -eq 0 ]
    cmp "$out/configs/ghostty/themes/terminal-noir-dark" "$ROOT/configs/ghostty/themes/terminal-noir-dark"
    cmp "$out/configs/ghostty/themes/terminal-noir-light" "$ROOT/configs/ghostty/themes/terminal-noir-light"
    cmp "$out/configs/vscode/terminal-noir/themes/terminal-noir-color-theme.json" "$ROOT/configs/vscode/terminal-noir/themes/terminal-noir-color-theme.json"
}

@test "a changed source color makes the build differ" {
    cp -r "$ROOT/configs" "$BATS_TEST_TMPDIR/configs"
    jq '.dark.terminal.background = "#000001"' \
        "$BATS_TEST_TMPDIR/configs/noctalia/palettes/Terminal Noir.json" \
        > "$BATS_TEST_TMPDIR/palette.json"
    mv "$BATS_TEST_TMPDIR/palette.json" "$BATS_TEST_TMPDIR/configs/noctalia/palettes/Terminal Noir.json"
    mkdir -p "$BATS_TEST_TMPDIR/scripts"
    cp -r "$ROOT/scripts/themes" "$BATS_TEST_TMPDIR/scripts/"
    out="$BATS_TEST_TMPDIR/out2"; mkdir -p "$out"
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="/usr/bin:/bin" DOTFILES="$BATS_TEST_TMPDIR" bash "$BATS_TEST_TMPDIR/scripts/themes/build-terminal-noir" --out "$out"
    [ "$status" -eq 0 ]
    ! cmp -s "$out/configs/ghostty/themes/terminal-noir-dark" "$ROOT/configs/ghostty/themes/terminal-noir-dark"
}

@test "the author name appears only in allowlisted credit lines" {
    local handle
    handle="$(printf '%s' "nando""moreira")"
    grep -q '^credit:' "$ROOT/scripts/public-check.allow"
    # Every theme credit line that names the author must match an allowfile entry.
    # (Deny/allow behavior of the gate itself is covered in public-check.bats.)
    while IFS= read -r hit; do
        [ -n "$hit" ] || continue
        file="${hit%%:*}"
        rest="${hit#*:}"
        line="${rest#*:}"
        grep -Fxq "credit:${file}:${line}" "$ROOT/scripts/public-check.allow"
    done < <(rg -n -- "$handle" \
        "$ROOT/configs/ghostty/themes" \
        "$ROOT/configs/vscode/terminal-noir" \
        "$ROOT/configs/themes/terminal-noir" \
        "$ROOT/configs/micro/colorschemes/terminal-noir.micro" \
        "$ROOT/scripts/themes" \
        "$ROOT/configs/bat/themes" 2>/dev/null | sed "s|^$ROOT/||")
}

@test "theme tools are in english" {
    run grep -nE "[áàâãéêíóôõúç]|\b(não|erro|arquivo)\b" "$ROOT/scripts/themes/"*
    [ "$status" -ne 0 ]
}

@test "syntax editor colors come from the palette dark side" {
    [ "$(jq -r '.editor.background' "$SYNTAX")" = "$(jq -r '.dark.mSurface' "$PALETTE")" ]
    [ "$(jq -r '.editor.foreground' "$SYNTAX")" = "$(jq -r '.dark.mOnSurface' "$PALETTE")" ]
    [ "$(jq -r '.editor.muted' "$SYNTAX")" = "$(jq -r '.dark.mOnSurfaceVariant' "$PALETTE")" ]
    [ "$(jq -r '.editor.surfaceElevated' "$SYNTAX")" = "$(jq -r '.dark.mSurfaceVariant' "$PALETTE")" ]
    [ "$(jq -r '.editor.borderStrong' "$SYNTAX")" = "$(jq -r '.dark.mOutline' "$PALETTE")" ]
    [ "$(jq -r '.editor.primary' "$SYNTAX")" = "$(jq -r '.dark.mPrimary' "$PALETTE")" ]
    [ "$(jq -r '.editor.success' "$SYNTAX")" = "$(jq -r '.dark.mSecondary' "$PALETTE")" ]
    [ "$(jq -r '.editor.error' "$SYNTAX")" = "$(jq -r '.dark.mError' "$PALETTE")" ]
}

@test "VS Code extension contributes a dark Terminal Noir theme" {
    jq -e '.contributes.themes[0] | .label == "Terminal Noir" and .uiTheme == "vs-dark"
        and .path == "./themes/terminal-noir-color-theme.json"' "$VSCODE_DIR/package.json"
    jq -e '.engines.vscode' "$VSCODE_DIR/package.json"
}

@test "VS Code theme paints the editor and keywords with the palette" {
    jq -e '.type == "dark"' "$VSCODE_THEME"
    [ "$(jq -r '.colors["editor.background"]' "$VSCODE_THEME")" = "#0B0B0C" ]
    [ "$(jq -r '.colors["editorCursor.foreground"]' "$VSCODE_THEME")" = "#F5A623" ]
    [ "$(jq -r '.colors["terminal.ansiYellow"]' "$VSCODE_THEME")" = "#F5A623" ]
    [ "$(jq -r '.tokenColors[] | select(.scope | index("keyword")) | .settings.foreground' "$VSCODE_THEME")" = "#F5A623" ]
    [ "$(jq -r '.tokenColors[] | select(.scope | index("string")) | .settings.foreground' "$VSCODE_THEME")" = "#34D399" ]
}

@test "bat theme is a plist with the palette background and keyword color" {
    grep -Fq '<!DOCTYPE plist' "$BAT_THEME"
    grep -Fq '<string>Terminal Noir</string>' "$BAT_THEME"
    grep -Fq '<key>background</key>' "$BAT_THEME"
    grep -Fq '<string>#0B0B0C</string>' "$BAT_THEME"
    if command -v xmllint >/dev/null 2>&1; then
        xmllint --noout "$BAT_THEME"
    fi
}

@test "Micro theme paints the editor with the palette" {
    grep -Fqx 'color-link default "#F4F4F5,#0B0B0C"' "$MICRO_THEME"
    grep -Fqx 'color-link statement "#F5A623"' "$MICRO_THEME"
    grep -Fqx 'color-link constant.string "#34D399"' "$MICRO_THEME"
    grep -Fqx 'color-link comment "italic #A1A1AA"' "$MICRO_THEME"
    grep -Fqx 'color-link current-line-number "#F5A623"' "$MICRO_THEME"
    grep -Fqx 'color-link cursor-line "#18181B,#F4F4F5"' "$MICRO_THEME"
}
