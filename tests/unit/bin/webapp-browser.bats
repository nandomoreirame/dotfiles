#!/usr/bin/env bats

# Unit tests for bin/utils/webapp-browser (REQ-002, REQ-007).
# Resolution order: $WEBAPP_BROWSER -> ~/.config/webappbar/browser -> xdg-settings -> chromium.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/webapp-browser"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    export HOME="$TEST_DIR/home"
    # Hermetic system data dirs: keep the XDG spec default from leaking host browsers in.
    export XDG_DATA_DIRS="$TEST_DIR/xdg-data"
    mkdir -p "$STUB_DIR" "$HOME/.local/share/applications" \
        "$XDG_DATA_DIRS/applications" "$XDG_CONFIG_HOME/webappbar"

    export PATH="$STUB_DIR:$PATH"

    # Stub xdg-settings: the desktop id comes from FAKE_XDG_ID, empty means "no answer".
    cat > "$STUB_DIR/xdg-settings" <<'STUB'
#!/usr/bin/env bash
[[ "$1" == "get" && "$2" == "default-web-browser" ]] || exit 2
[[ -n "${FAKE_XDG_ID:-}" ]] || exit 1
printf '%s\n' "$FAKE_XDG_ID"
STUB
    chmod +x "$STUB_DIR/xdg-settings"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "env var wins over everything" {
    export WEBAPP_BROWSER=brave-browser
    export FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" --get
    [ "$status" -eq 0 ]
    [ "$output" = "brave-browser" ]
}

@test "config file decides when the env var is unset" {
    printf 'vivaldi-stable\n' > "$XDG_CONFIG_HOME/webappbar/browser"
    printf '%s\n' "/usr/bin/vivaldi-stable" > "$TEST_DIR/vivaldi-stable"
    export FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" --get
    [ "$status" -eq 0 ]
    [ "$output" = "vivaldi-stable" ]
}

@test "falls back to the xdg default when it is a Chromium family" {
    export FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" --get
    [ "$output" = "google-chrome" ]
}

@test "ignores a non-Chromium default and picks the first installed in preference order" {
    export FAKE_XDG_ID=firefox.desktop
    printf '[Desktop Entry]\nExec=/usr/bin/chromium %%U\n' \
        > "$XDG_DATA_DIRS/applications/chromium.desktop"
    printf '[Desktop Entry]\nExec=/usr/bin/google-chrome %%U\n' \
        > "$XDG_DATA_DIRS/applications/google-chrome.desktop"
    run "$SCRIPT" --get
    [ "$output" = "google-chrome" ]
}

@test "falls back to chromium when nothing is installed" {
    export FAKE_XDG_ID=firefox.desktop
    run "$SCRIPT" --get
    [ "$output" = "chromium" ]
}

@test "custom binary in the config file is used verbatim" {
    printf '/opt/thorium/thorium\n' > "$XDG_CONFIG_HOME/webappbar/browser"
    run "$SCRIPT" --get
    [ "$output" = "/opt/thorium/thorium" ]
}

@test "set writes the config file and list reports known ids" {
    run "$SCRIPT" set brave-browser
    [ "$status" -eq 0 ]
    [ "$(cat "$XDG_CONFIG_HOME/webappbar/browser")" = "brave-browser" ]
    printf '[Desktop Entry]\nExec=/usr/bin/brave-browser %%U\n' > "$HOME/.local/share/applications/brave-browser.desktop"
    run "$SCRIPT" --list
    [ "$output" = "brave-browser" ]
}

@test "rejects an unknown command" {
    run "$SCRIPT" --nope
    [ "$status" -ne 0 ]
}

# --exec maps the logical name to the executable that actually exists: on many
# systems google-chrome is only installed as google-chrome-stable.

@test "--exec keeps a binary that is on PATH" {
    cat > "$STUB_DIR/chromium" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "$STUB_DIR/chromium"
    export WEBAPP_BROWSER=chromium
    run "$SCRIPT" --exec
    [ "$status" -eq 0 ]
    [ "$output" = "chromium" ]
}

@test "--exec maps a PATH-less logical name through its desktop Exec line" {
    printf '[Desktop Entry]\nExec=/usr/bin/google-chrome-stable %%U\n' \
        > "$XDG_DATA_DIRS/applications/google-chrome.desktop"
    export FAKE_XDG_ID=google-chrome.desktop
    run "$SCRIPT" --exec
    [ "$status" -eq 0 ]
    [ "$output" = "/usr/bin/google-chrome-stable" ]
}

@test "--exec keeps an absolute custom binary verbatim" {
    printf '/opt/thorium/thorium\n' > "$XDG_CONFIG_HOME/webappbar/browser"
    run "$SCRIPT" --exec
    [ "$output" = "/opt/thorium/thorium" ]
}

@test "--exec falls back to the logical name when nothing resolves it" {
    export WEBAPP_BROWSER=brave-browser
    run "$SCRIPT" --exec
    [ "$output" = "brave-browser" ]
}
