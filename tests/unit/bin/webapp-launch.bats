#!/usr/bin/env bats

# Unit tests for bin/utils/webapp-launch (REQ-007).

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/webapp-launch"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    export HOME="$TEST_DIR/home"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    # Hermetic system data dirs: keep the XDG spec default from leaking host browsers in.
    export XDG_DATA_DIRS="$TEST_DIR/xdg-data"
    mkdir -p "$HOME/.local/share/applications" "$STUB_DIR" \
        "$XDG_CONFIG_HOME/webappbar" "$XDG_DATA_DIRS/applications"
    export PATH="$STUB_DIR:$PROJECT_ROOT/bin/utils:/usr/bin:/bin"

    # Stub the browser so we only assert the argv.
    cat > "$STUB_DIR/chromium" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_ARGV_FILE"
STUB
    chmod +x "$STUB_DIR/chromium"
    export FAKE_ARGV_FILE="$TEST_DIR/argv"
    export WEBAPP_BROWSER=chromium
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "launches app mode with the resolved browser and passes extra args" {
    run "$SCRIPT" https://music.youtube.com --new-window
    [ "$status" -eq 0 ]
    [ "$(sed -n 1p "$FAKE_ARGV_FILE")" = "--app=https://music.youtube.com" ]
    [ "$(sed -n 2p "$FAKE_ARGV_FILE")" = "--new-window" ]
}

@test "resolves through webapp-browser (honours WEBAPP_BROWSER)" {
    cat > "$STUB_DIR/brave-browser" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_ARGV_FILE"
STUB
    chmod +x "$STUB_DIR/brave-browser"
    export WEBAPP_BROWSER=brave-browser
    run "$SCRIPT" https://a.example
    [ "$status" -eq 0 ]
    [ "$(sed -n 1p "$FAKE_ARGV_FILE")" = "--app=https://a.example" ]
}

@test "requires a URL" {
    run "$SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: webapp-launch"* ]]
}
