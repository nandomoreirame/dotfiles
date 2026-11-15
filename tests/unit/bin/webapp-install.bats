#!/usr/bin/env bats

# Unit tests for bin/utils/webapp-install (REQ-003, REQ-007).

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/webapp-install"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    export HOME="$TEST_DIR/home"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    # Hermetic system data dirs: keep the XDG spec default from leaking host browsers in.
    export XDG_DATA_DIRS="$TEST_DIR/xdg-data"
    mkdir -p "$HOME/.local/share/applications" "$XDG_CONFIG_HOME/webappbar" \
        "$XDG_DATA_DIRS/applications"
    mkdir -p "$STUB_DIR"
    export PATH="$STUB_DIR:$PROJECT_ROOT/bin/utils:/usr/bin:/bin"

    cat > "$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
# Never touch the network: write one byte to the -o target.
while (($#)); do
    case "$1" in
    -o) shift; printf 'x' > "$1" ;;
    esac
    shift
done
STUB
    chmod +x "$STUB_DIR/curl"
    cat > "$STUB_DIR/update-desktop-database" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "$STUB_DIR/update-desktop-database"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "writes a managed entry with a direct Exec" {
    export WEBAPP_BROWSER=brave-browser
    run "$SCRIPT" "YouTube Music" music.youtube.com
    [ "$status" -eq 0 ]
    entry="$HOME/.local/share/applications/YouTube Music.desktop"
    [ -f "$entry" ]
    grep -q '^Exec="brave-browser" --app="https://music.youtube.com"$' "$entry"
    grep -q '^X-Webappbar-Id=YouTube Music$' "$entry"
    grep -q '^X-Webappbar-Url=https://music.youtube.com$' "$entry"
    grep -q '^X-Webappbar-Browser=brave-browser$' "$entry"
    grep -q '^Icon=.*/icons/YouTube Music.png$' "$entry"
}

@test "keeps the explicit icon reference as a local path" {
    run "$SCRIPT" Gmail mail.google.com gmail.png
    entry="$HOME/.local/share/applications/Gmail.desktop"
    grep -q '^Icon=.*/applications/icons/gmail.png$' "$entry"
}

@test "--list separates managed, legacy and chrome entries" {
    printf '[Desktop Entry]\nName=Mine\nExec="chromium" --app="https://a.example"\nX-Webappbar-Id=Mine\n' \
        > "$HOME/.local/share/applications/Mine.desktop"
    printf '[Desktop Entry]\nName=Old\nExec=$HOME/bin/webapp-launch https://b.example\n' \
        > "$HOME/.local/share/applications/Old.desktop"
    printf '[Desktop Entry]\nName=Pwa\nExec=/usr/bin/google-chrome --app-id=abcdef\n' \
        > "$HOME/.local/share/applications/chrome-abcdef-Default.desktop"
    run "$SCRIPT" --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"[webapp]"*"Mine"* ]]
    [[ "$output" == *"[legacy]"*"Old"* ]]
    [[ "$output" == *"[chrome]"*"Pwa"* ]]
}

@test "fails without a name or URL" {
    run "$SCRIPT" "" "https://x.dev"
    [ "$status" -ne 0 ]
}

@test "escapes percent in Exec but keeps the raw URL in the marker" {
    export WEBAPP_BROWSER=chromium
    run "$SCRIPT" "Search" "https://a.example/?q=50%25"
    [ "$status" -eq 0 ]
    entry="$HOME/.local/share/applications/Search.desktop"
    grep -q '^Exec="chromium" --app="https://a.example/?q=50%%25"$' "$entry"
    grep -q '^X-Webappbar-Url=https://a.example/?q=50%25$' "$entry"
}
