#!/usr/bin/env bats

# Unit tests for bin/utils/webapp-remove (REQ-007).

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/webapp-remove"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    export HOME="$TEST_DIR/home"
    export XDG_DATA_DIRS="$TEST_DIR/xdg-data"
    export PATH="$STUB_DIR:/usr/bin:/bin"
    APPS="$HOME/.local/share/applications"
    mkdir -p "$APPS/icons" "$STUB_DIR" "$XDG_DATA_DIRS"

    printf 'x' > "$APPS/icons/Mine.png"
    printf '[Desktop Entry]\nName=Mine\nExec="chromium" --app="https://a.example"\nX-Webappbar-Id=Mine\n' \
        > "$APPS/Mine.desktop"
    printf '[Desktop Entry]\nName=Pwa\nExec=/usr/bin/google-chrome --app-id=abc\n' \
        > "$APPS/chrome-abc-Default.desktop"

    cat > "$STUB_DIR/update-desktop-database" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "$STUB_DIR/update-desktop-database"
    cat > "$STUB_DIR/fzf" <<'STUB'
#!/usr/bin/env bash
cat
STUB
    chmod +x "$STUB_DIR/fzf"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "removes a managed entry and its icon by id" {
    run "$SCRIPT" Mine
    [ "$status" -eq 0 ]
    [ ! -f "$APPS/Mine.desktop" ]
    [ ! -f "$APPS/icons/Mine.png" ]
    [[ "$output" == *"Removed Mine"* ]]
}

@test "interactive removal discovers managed entries" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [ ! -f "$APPS/Mine.desktop" ]
    [ ! -f "$APPS/icons/Mine.png" ]
    [[ "$output" == *"Removed Mine"* ]]
}

@test "removes a legacy entry and its icon by id" {
    printf 'x' > "$APPS/icons/Old.png"
    printf '[Desktop Entry]\nName=Old\nExec=/usr/bin/webapp-launch https://old.example\n' \
        > "$APPS/Old.desktop"
    run "$SCRIPT" Old
    [ "$status" -eq 0 ]
    [ ! -f "$APPS/Old.desktop" ]
    [ ! -f "$APPS/icons/Old.png" ]
}

@test "warns instead of removing a chrome PWA" {
    run "$SCRIPT" Pwa
    [ "$status" -eq 0 ]
    [ -f "$APPS/chrome-abc-Default.desktop" ]
    [[ "$output" == *"chrome://apps"* ]]
}

@test "does not remove an unrelated desktop entry or its icon" {
    printf 'x' > "$APPS/icons/Other.png"
    printf '[Desktop Entry]\nName=Other\nExec=/usr/bin/other\n' > "$APPS/Other.desktop"
    run "$SCRIPT" Other
    [ "$status" -eq 0 ]
    [ -f "$APPS/Other.desktop" ]
    [ -f "$APPS/icons/Other.png" ]
    [[ "$output" == *"No web app named 'Other' found"* ]]
}

@test "warns when the name does not exist" {
    run "$SCRIPT" Nope
    [ "$status" -eq 0 ]
    [[ "$output" == *"No web app named 'Nope' found"* ]]
}

@test "rejects unsafe ids without removing files" {
    printf '[Desktop Entry]\nName=Outside\nX-Webappbar-Id=../Outside\n' \
        > "$HOME/.local/share/Outside.desktop"
    printf 'x' > "$APPS/Outside.png"

    local id
    for id in '../Outside' '.Mine' 'Mine\Other' $'Mine\nOther'; do
        run "$SCRIPT" "$id"
        [ "$status" -eq 0 ]
        [[ "$output" == *"No web app named"* ]]
    done

    [ -f "$HOME/.local/share/Outside.desktop" ]
    [ -f "$APPS/Outside.png" ]
    [ -f "$APPS/Mine.desktop" ]
}
