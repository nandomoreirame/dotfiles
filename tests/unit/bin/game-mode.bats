#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    FAKE="$BATS_TEST_TMPDIR/fake"; CALLS="$BATS_TEST_TMPDIR/calls"; mkdir -p "$FAKE"; : > "$CALLS"
    for c in pkill kill pgrep; do printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$c" "$CALLS" > "$FAKE/$c"; chmod +x "$FAKE/$c"; done
}

@test "game-mode uses GAME_MODE_APPS" {
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="$FAKE:/usr/bin:/bin" GAME_MODE_APPS="alpha beta" bash "$ROOT/bin/utils/game-mode" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* && "$output" == *"beta"* ]]
}

@test "game-mode default list names no personal app" {
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="$FAKE:/usr/bin:/bin" bash "$ROOT/bin/utils/game-mode" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" != *"rdo"* && "$output" != *"obs-live"* ]]
}

@test "game-mode is in english and carries no personal string" {
    run grep -nE "jane|/home/|homelab|[áàâãéêíóôõúç]" "$ROOT/bin/utils/game-mode"
    [ "$status" -ne 0 ]
}

@test "game-mode default GAME_MODE_APPS entries fit /proc/comm (15 chars)" {
    # shellcheck disable=SC1091
    list="$(sed -n 's/^: "${GAME_MODE_APPS:=\([^}"]*\)}"/\1/p' "$ROOT/bin/utils/game-mode")"
    [ -n "$list" ]
    for a in $list; do
        [ "${#a}" -le 15 ]
    done
}

@test "game-mode on freezes only GAME_MODE_APPS scopes in a fake cgroup tree" {
    CG="$BATS_TEST_TMPDIR/cg"
    RT="$BATS_TEST_TMPDIR/run"
    mkdir -p "$CG" "$RT" "$FAKE"

    # Fake scopes: chromium (should freeze), other-app (should not), Steam (kept + steam_running).
    for name in app-chromium-111.scope app-other-app-222.scope app-Steam-333.scope; do
        mkdir -p "$CG/$name"
        : > "$CG/$name/cgroup.procs"
        printf '0\n' > "$CG/$name/cgroup.freeze"
        printf 'frozen 0\n' > "$CG/$name/cgroup.events"
    done

    # nocta-hold sibling stub (game-mode resolves HOLD next to SELF).
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    cp "$ROOT/bin/utils/game-mode" "$BATS_TEST_TMPDIR/bin/game-mode"
    cat > "$BATS_TEST_TMPDIR/bin/nocta-hold" <<'STUB'
#!/bin/sh
exit 0
STUB
    chmod +x "$BATS_TEST_TMPDIR/bin/nocta-hold" "$BATS_TEST_TMPDIR/bin/game-mode"

    # pgrep -x steamwebhelper must fail; Steam scope covers steam_running.
    cat > "$FAKE/pgrep" <<STUB
#!/bin/sh
echo "pgrep \$*" >> "$CALLS"
exit 1
STUB
    chmod +x "$FAKE/pgrep"
    cat > "$FAKE/notify-send" <<'STUB'
#!/bin/sh
exit 0
STUB
    chmod +x "$FAKE/notify-send"

    run env -i HOME="$BATS_TEST_TMPDIR" PATH="$FAKE:/usr/bin:/bin" \
        XDG_RUNTIME_DIR="$RT" \
        GAME_MODE_APP_CG="$CG" \
        GAME_MODE_APPS="chromium" \
        GAME_MODE_KEEP_OUTPUTS=1 \
        bash "$BATS_TEST_TMPDIR/bin/game-mode" on

    [ "$status" -eq 0 ]
    [ "$(cat "$CG/app-chromium-111.scope/cgroup.freeze")" = "1" ]
    [ "$(cat "$CG/app-other-app-222.scope/cgroup.freeze")" = "0" ]
    [ "$(cat "$CG/app-Steam-333.scope/cgroup.freeze")" = "0" ]
    [ -f "$RT/game-mode.active" ]
}

# Two presses while the first is still freezing (pw-dump is slow) must not race:
# the second waits for the lock, then turns game mode off.
@test "game-mode serializes concurrent toggles with a lock" {
    CG="$BATS_TEST_TMPDIR/cg"; RT="$BATS_TEST_TMPDIR/run"
    mkdir -p "$RT" "$BATS_TEST_TMPDIR/bin"
    # The Steam scope makes steam_running true, so `on` really freezes.
    for name in app-chromium-111.scope app-Steam-333.scope; do
        mkdir -p "$CG/$name"
        : > "$CG/$name/cgroup.procs"
        printf '0\n' > "$CG/$name/cgroup.freeze"
        printf 'frozen 0\n' > "$CG/$name/cgroup.events"
    done
    cp "$ROOT/bin/utils/game-mode" "$BATS_TEST_TMPDIR/bin/game-mode"
    printf '#!/bin/sh\nexit 0\n' > "$BATS_TEST_TMPDIR/bin/nocta-hold"
    printf '#!/bin/sh\nexit 1\n' > "$FAKE/pgrep"
    printf '#!/bin/sh\nexit 0\n' > "$FAKE/notify-send"
    printf '#!/bin/sh\nsleep 1\necho "[]"\n' > "$FAKE/pw-dump"
    chmod +x "$BATS_TEST_TMPDIR/bin/"* "$FAKE/"*
    gm() {
        env -i HOME="$BATS_TEST_TMPDIR" PATH="$FAKE:/usr/bin:/bin" XDG_RUNTIME_DIR="$RT" \
            GAME_MODE_APP_CG="$CG" GAME_MODE_APPS="chromium" GAME_MODE_KEEP_OUTPUTS=1 \
            timeout 20 bash "$BATS_TEST_TMPDIR/bin/game-mode" toggle
    }
    gm & first=$!
    sleep 0.3
    gm
    wait "$first"
    [ ! -f "$RT/game-mode.active" ]
    [ "$(cat "$CG/app-chromium-111.scope/cgroup.freeze")" = "0" ]
}

@test "game-mode closes the lock fd for long-lived children" {
    run grep -cE '9>&-' "$ROOT/bin/utils/game-mode"
    [ "$output" -ge 5 ]
}
