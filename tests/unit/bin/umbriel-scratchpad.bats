#!/usr/bin/env bats

# Unit tests for bin/utils/umbriel-scratchpad
#
# Run:
#   ./tests/run-tests tests/unit/bin/umbriel-scratchpad.bats
#
# An app that closes to the tray (Spotify, Chrome webapps, Grok) can leave its
# floating window outside its scratchpad: Umbriel keeps it "visible", never
# draws it and still routes clicks to it. `toggle` fixes such orphans before
# it runs `scratchpad-toggle`:
#   - an orphan goes back into its scratchpad when that scratchpad is empty
#   - an orphan that stays out after the move gets minimized
#   - a visible orphan next to a scratchpad member gets minimized (no duplicate)
#   - tiled windows and other app ids are left alone
#
# `close` backs Ctrl+Q and Mod+Q: a scratchpad window is closed for good
# (window-kill) when its client owns no other window; a shared client (Chrome
# webapps) gets window-close, and a window that survives it gets minimized.
#
# `tile` backs Mod+Shift+V and is a toggle: the active scratchpad window is
# restored from its scratchpad and tiled (floating toggled off only when it
# stays floating); an active window outside any scratchpad whose app id matches
# a `default_scratchpad` rule goes back into that scratchpad and is revealed
# (window-focus), since the move alone hides it.
#
# `umbriel` is stubbed on PATH: `subscribe windows` prints FAKE_WINDOWS (or
# FAKE_WINDOWS_AFTER_MOVE once a move-to-scratchpad was logged) and every
# `msg` call is recorded in CALL_LOG.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/bin/utils/umbriel-scratchpad"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"
    CONF_DIR="$TEST_DIR/xdg/umbriel"

    mkdir -p "$STUB_DIR" "$CONF_DIR"
    : > "$CALL_LOG"

    cat > "$CONF_DIR/base.toml" <<'TOML'
[[scratchpad]]
name = "spotify"
spawn_when_empty = "spotify-launcher"

[[window_rule]]
match.app_id = "^[Ss]potify$"
default_scratchpad = "spotify"
TOML

    cat > "$CONF_DIR/private.toml" <<'TOML'
[[window_rule]]
match.app_id = "^chrome-web[.]whatsapp[.]com__-"
default_scratchpad = "whatsapp"
TOML

    cat > "$STUB_DIR/umbriel" <<'STUB'
#!/usr/bin/env bash
if [ "$1" = "subscribe" ]; then
    if [ -n "${FAKE_WINDOWS_AFTER_RESTORE:-}" ] && grep -q 'window-restore-from-scratchpad' "$CALL_LOG"; then
        printf '{"event":"windows","data":%s}\n' "$FAKE_WINDOWS_AFTER_RESTORE"
    elif [ -n "${FAKE_WINDOWS_AFTER_CLOSE:-}" ] && grep -q 'window-close' "$CALL_LOG"; then
        printf '{"event":"windows","data":%s}\n' "$FAKE_WINDOWS_AFTER_CLOSE"
    elif [ -n "${FAKE_WINDOWS_AFTER_MOVE:-}" ] && grep -q 'window-move-to-scratchpad' "$CALL_LOG"; then
        printf '{"event":"windows","data":%s}\n' "$FAKE_WINDOWS_AFTER_MOVE"
    else
        printf '{"event":"windows","data":%s}\n' "$FAKE_WINDOWS"
    fi
    exit 0
fi
echo "umbriel $*" >> "$CALL_LOG"
exit 0
STUB

    chmod +x "$STUB_DIR"/*
}

teardown() {
    temp_del "$TEST_DIR"
}

# `env -i` is required: BASH_ENV re-prepends PATH and would shadow the stubs.
run_wrapper() {
    run env -i \
        HOME="$TEST_DIR" \
        PATH="$STUB_DIR:/usr/bin:/bin" \
        XDG_CONFIG_HOME="$TEST_DIR/xdg" \
        CALL_LOG="$CALL_LOG" \
        FAKE_WINDOWS="${FAKE_WINDOWS:-[]}" \
        FAKE_WINDOWS_AFTER_MOVE="${FAKE_WINDOWS_AFTER_MOVE:-}" \
        FAKE_WINDOWS_AFTER_CLOSE="${FAKE_WINDOWS_AFTER_CLOSE:-}" \
        FAKE_WINDOWS_AFTER_RESTORE="${FAKE_WINDOWS_AFTER_RESTORE:-}" \
        UMBRIEL_SCRATCHPAD_CLOSE_WAIT=0 \
        timeout 10 "$SCRIPT" "$@"
}

# win <id> <app_id> <scratchpad> <floating> <visible> <minimized>
win() {
    printf '{"id":"%s","app_id":"%s","scratchpad":"%s","floating":%s,"visible":%s,"minimized":%s}' \
        "$1" "$2" "$3" "$4" "$5" "$6"
}

# winp <id> <app_id> <scratchpad> <pid> <active>: a window for the close tests.
winp() {
    printf '{"id":"%s","app_id":"%s","scratchpad":"%s","pid":%s,"active":%s,"floating":true,"visible":true,"minimized":false}' \
        "$1" "$2" "$3" "$4" "$5"
}

@test "fails with usage when no scratchpad name is given" {
    run_wrapper toggle

    assert_failure
    assert_output --partial "usage"
}

@test "without orphans it only toggles the scratchpad" {
    FAKE_WINDOWS="[$(win s1 Spotify spotify true false false)]" run_wrapper toggle spotify

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg scratchpad-toggle spotify"
}

@test "an orphan goes back into its empty scratchpad before the toggle" {
    FAKE_WINDOWS="[$(win o1 Spotify '' true true false)]" \
    FAKE_WINDOWS_AFTER_MOVE="[$(win o1 Spotify spotify true false false)]" \
        run_wrapper toggle spotify

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-focus o1
umbriel msg window-move-to-scratchpad spotify
umbriel msg scratchpad-toggle spotify"
}

@test "a minimized orphan is also adopted when the scratchpad is empty" {
    FAKE_WINDOWS="[$(win o1 Spotify '' true false true)]" \
    FAKE_WINDOWS_AFTER_MOVE="[$(win o1 Spotify spotify true false false)]" \
        run_wrapper toggle spotify

    assert_success
    run grep -c 'window-move-to-scratchpad spotify' "$CALL_LOG"
    assert_output "1"
}

@test "an orphan that stays out after the move gets minimized" {
    FAKE_WINDOWS="[$(win o1 Spotify '' true true false)]" run_wrapper toggle spotify

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-focus o1
umbriel msg window-move-to-scratchpad spotify
umbriel msg window-minimize o1
umbriel msg scratchpad-toggle spotify"
}

@test "a visible orphan next to a scratchpad member gets minimized, not adopted" {
    FAKE_WINDOWS="[$(win m1 chrome-web.whatsapp.com__-Default whatsapp true false false),$(win o1 chrome-web.whatsapp.com__-Default '' true true false)]" \
        run_wrapper toggle whatsapp

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-minimize o1
umbriel msg scratchpad-toggle whatsapp"
}

@test "an already minimized orphan next to a member is left alone" {
    FAKE_WINDOWS="[$(win m1 Spotify spotify true false false),$(win o1 Spotify '' true false true)]" \
        run_wrapper toggle spotify

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg scratchpad-toggle spotify"
}

@test "tiled windows and other app ids are never touched" {
    FAKE_WINDOWS="[$(win t1 Spotify '' false true false),$(win g1 grok-bot '' true true false)]" \
        run_wrapper toggle spotify

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg scratchpad-toggle spotify"
}

@test "close on a regular window sends window-close" {
    FAKE_WINDOWS="[$(winp t1 com.mitchellh.ghostty '' 10 true)]" run_wrapper close

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-close t1"
}

@test "close on a scratchpad window with its own client kills the client" {
    FAKE_WINDOWS="[$(winp s1 Spotify spotify 20 true),$(winp t1 com.mitchellh.ghostty '' 10 false)]" run_wrapper close

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-kill s1"
}

@test "close on a scratchpad window that shares its client never kills it" {
    FAKE_WINDOWS="[$(winp w1 chrome-web.whatsapp.com__-Default whatsapp 30 true),$(winp c1 google-chrome '' 30 false)]" \
        run_wrapper close

    assert_success
    run cat "$CALL_LOG"
    refute_output --partial "window-kill"
    assert_line "umbriel msg window-close w1"
}

@test "a shared-client scratchpad window that survives the close gets minimized" {
    FAKE_WINDOWS="[$(winp w1 chrome-web.whatsapp.com__-Default whatsapp 30 true),$(winp c1 google-chrome '' 30 false)]" \
    FAKE_WINDOWS_AFTER_CLOSE="[$(winp w1 chrome-web.whatsapp.com__-Default '' 30 false),$(winp c1 google-chrome '' 30 false)]" \
        run_wrapper close

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-close w1
umbriel msg window-minimize w1"
}

@test "a shared-client scratchpad window that is gone after the close is left alone" {
    FAKE_WINDOWS="[$(winp w1 chrome-web.whatsapp.com__-Default whatsapp 30 true),$(winp c1 google-chrome '' 30 false)]" \
    FAKE_WINDOWS_AFTER_CLOSE="[$(winp c1 google-chrome '' 30 false)]" \
        run_wrapper close

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-close w1"
}

@test "close without an active window does nothing" {
    FAKE_WINDOWS="[$(winp t1 com.mitchellh.ghostty '' 10 false)]" run_wrapper close

    assert_success
    run cat "$CALL_LOG"
    assert_output ""
}

@test "a scratchpad without a window rule still toggles" {
    FAKE_WINDOWS="[$(win o1 Spotify '' true true false)]" run_wrapper toggle youtube

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg scratchpad-toggle youtube"
}

@test "tile restores the active scratchpad window and tiles it when it stays floating" {
    FAKE_WINDOWS="[$(winp o1 obsidian obsidian 40 true)]" \
    FAKE_WINDOWS_AFTER_RESTORE="[$(winp o1 obsidian '' 40 true)]" \
        run_wrapper tile

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-restore-from-scratchpad obsidian
umbriel msg window-toggle-floating o1"
}

@test "tile does not toggle floating when the restored window is already tiled" {
    FAKE_WINDOWS="[$(winp o1 obsidian obsidian 40 true)]" \
    FAKE_WINDOWS_AFTER_RESTORE="[$(win o1 obsidian '' false true false)]" \
        run_wrapper tile

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-restore-from-scratchpad obsidian"
}

@test "tile on a window outside any scratchpad does nothing" {
    FAKE_WINDOWS="[$(winp t1 com.mitchellh.ghostty '' 10 true)]" run_wrapper tile

    assert_success
    run cat "$CALL_LOG"
    assert_output ""
}

@test "tile sends a tiled window back into the scratchpad its rule names" {
    FAKE_WINDOWS="[$(winp s1 Spotify '' 20 true)]" run_wrapper tile

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-move-to-scratchpad spotify
umbriel msg window-focus s1"
}

@test "tile finds the scratchpad in any config file, not only base.toml" {
    FAKE_WINDOWS="[$(winp w1 chrome-web.whatsapp.com__-Default '' 30 true)]" run_wrapper tile

    assert_success
    run cat "$CALL_LOG"
    assert_output "umbriel msg window-move-to-scratchpad whatsapp
umbriel msg window-focus w1"
}
