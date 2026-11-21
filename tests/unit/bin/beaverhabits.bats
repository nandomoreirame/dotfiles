#!/usr/bin/env bats

# Unit tests for bin/utils/beaverhabits (Beaver Habits REST API client used by
# the Vicinae script commands in configs/vicinae/scripts).
#
# A stub curl answers the export and completion endpoints and logs every call.
# `env -i` is required: BASH_ENV re-prepends PATH and would shadow the stubs.

load '../../bats/helpers/setup'
bats_require_minimum_version 1.5.0

SCRIPT="$PROJECT_ROOT/bin/utils/beaverhabits"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"
    XDG="$TEST_DIR/xdg"
    TOKEN="token-$RANDOM-abc"
    mkdir -p "$STUB_DIR" "$XDG/beaverhabits"
    : > "$CALL_LOG"
    printf 'OTHER=1\nAPI_TOKEN=%s\n' "$TOKEN" > "$TEST_DIR/app.env"

    # "Cat litter" done today, "English" undone today after a done record,
    # "Dishes" done yesterday only, "Old" archived.
    cat > "$TEST_DIR/export.json" <<'JSON'
{"habits": [
  {"id": "a1", "name": "Cat litter", "records": [
    {"day": "2026-11-21", "done": true, "timestamp": 1}]},
  {"id": "b2", "name": "English", "records": [
    {"day": "2026-11-21", "done": false, "timestamp": 2},
    {"day": "2026-11-20", "done": true, "timestamp": 1}]},
  {"id": "c3", "name": "Dishes", "records": [
    {"day": "2026-11-20", "done": true, "timestamp": 1}]},
  {"id": "d4", "name": "Old", "status": "archived", "records": []}
], "order_by": "manually", "order": []}
JSON

    cat > "$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
# Logs "METHOD URL BODY AUTH" where AUTH is ok|missing (never the token).
method=GET url="" body="" auth=missing
while [ "$#" -gt 0 ]; do
    case "$1" in
    -X) method="$2"; shift ;;
    --data) body="$2"; shift ;;
    --header)
        if [ "${2:0:1}" = "@" ] && grep -Fqx "Authorization: Bearer $EXPECTED_TOKEN" "${2:1}"; then
            auth=ok
        fi
        shift ;;
    http*) url="$1" ;;
    esac
    shift
done
echo "$method $url $body $auth" >> "$CALL_LOG"
[ -n "${FAKE_CURL_FAIL:-}" ] && { echo "curl: (22) The requested URL returned error: 401" >&2; exit 22; }
case "$method $url" in
"GET "*/api/v1/habits/export) cat "$EXPORT_JSON" ;;
"POST "*/completions) echo '{"day":"21-11-2026","done":true}' ;;
*) exit 22 ;;
esac
STUB
    chmod +x "$STUB_DIR"/*
}

teardown() {
    temp_del "$TEST_DIR"
}

# Env-driven run: URL and token pointer come from the environment.
run_bh() {
    run --separate-stderr env -i \
        HOME="$TEST_DIR" PATH="$STUB_DIR:/usr/bin:/bin" XDG_CONFIG_HOME="$XDG" \
        CALL_LOG="$CALL_LOG" EXPORT_JSON="$TEST_DIR/export.json" EXPECTED_TOKEN="$TOKEN" \
        FAKE_CURL_FAIL="${FAKE_CURL_FAIL:-}" \
        BEAVERHABITS_URL="${BH_URL-https://habits.test}" \
        BEAVERHABITS_ENV_FILE="${BH_ENV_FILE-$TEST_DIR/app.env}" \
        BEAVERHABITS_TODAY="2026-11-21" ${NO_COLOR:+NO_COLOR=1} \
        bash "$SCRIPT" "$@"
}

# Config-file run: nothing but HOME, PATH and XDG_CONFIG_HOME in the environment.
run_cfg() {
    run --separate-stderr env -i \
        HOME="$TEST_DIR" PATH="$STUB_DIR:/usr/bin:/bin" XDG_CONFIG_HOME="$XDG" \
        CALL_LOG="$CALL_LOG" EXPORT_JSON="$TEST_DIR/export.json" EXPECTED_TOKEN="$TOKEN" \
        BEAVERHABITS_TODAY="2026-11-21" \
        bash "$SCRIPT" "$@"
}

@test "list shows today's status of the active habits" {
    run_bh list
    [ "$status" -eq 0 ]
    [ "$output" = "$(printf '%s\n' '✓ Cat litter' '○ English' '○ Dishes')" ]
    grep -Fqx "GET https://habits.test/api/v1/habits/export  ok" "$CALL_LOG"
}

@test "list makes one request for all habits" {
    run_bh list
    [ "$(wc -l < "$CALL_LOG")" -eq 1 ]
}

@test "done resolves a case-insensitive unique substring and posts today" {
    run_bh done "engl"
    [ "$status" -eq 0 ]
    grep -Fqx 'POST https://habits.test/api/v1/habits/b2/completions {"done":true,"date":"21-11-2026","date_fmt":"%d-%m-%Y"} ok' "$CALL_LOG"
    [[ "$output" == *"English: done today"* ]]
}

@test "undo posts done false" {
    run_bh undo "cat litter"
    [ "$status" -eq 0 ]
    grep -Fq '/habits/a1/completions {"done":false,' "$CALL_LOG"
    [[ "$output" == *"Cat litter: not done today"* ]]
}

@test "exact name wins over a longer match" {
    printf '%s' '{"habits":[{"id":"x","name":"Read","records":[]},{"id":"y","name":"Read paper","records":[]}]}' > "$TEST_DIR/export.json"
    run_bh done "read"
    [ "$status" -eq 0 ]
    grep -Fq '/habits/x/completions' "$CALL_LOG"
}

@test "ambiguous name exits 2 and lists the candidates" {
    run_bh done "i"
    [ "$status" -eq 2 ]
    [[ "$stderr" == *"Cat litter"* ]]
    ! grep -q '^POST' "$CALL_LOG"
}

@test "unknown or archived name exits 2 without posting" {
    run_bh done "running"
    [ "$status" -eq 2 ]
    run_bh done "old"
    [ "$status" -eq 2 ]
    ! grep -q '^POST' "$CALL_LOG"
}

@test "missing name exits 2" {
    run_bh done
    [ "$status" -eq 2 ]
}

@test "a habit id outside [A-Za-z0-9_-] is refused before any POST" {
    printf '%s' '{"habits":[{"id":"../account","name":"Evil","records":[]}]}' > "$TEST_DIR/export.json"
    run_bh done "evil"
    [ "$status" -eq 3 ]
    ! grep -q '^POST' "$CALL_LOG"
}

@test "missing URL exits 1 without calling the API" {
    BH_URL="" run_bh list
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"BEAVERHABITS_URL"* ]]
    [ ! -s "$CALL_LOG" ]
}

@test "a URL that is not http or https exits 1" {
    BH_URL="file:///etc/passwd" run_bh list
    [ "$status" -eq 1 ]
    [ ! -s "$CALL_LOG" ]
}

@test "missing token exits 1 without calling the API" {
    BH_ENV_FILE="$TEST_DIR/none.env" run_bh list
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"token"* ]]
    [ ! -s "$CALL_LOG" ]
}

@test "the config file supplies the URL and the token pointer" {
    printf 'BEAVERHABITS_URL="https://cfg.test"\nBEAVERHABITS_ENV_FILE=~/app.env\n' > "$XDG/beaverhabits/env"
    run_cfg list
    [ "$status" -eq 0 ]
    grep -Fqx "GET https://cfg.test/api/v1/habits/export  ok" "$CALL_LOG"
}

@test "the config file can hold the token itself" {
    printf 'BEAVERHABITS_URL=https://cfg.test\nBEAVERHABITS_TOKEN=%s\n' "$TOKEN" > "$XDG/beaverhabits/env"
    run_cfg list
    [ "$status" -eq 0 ]
    grep -Fq " ok" "$CALL_LOG"
}

@test "environment variables win over the config file" {
    printf 'BEAVERHABITS_URL=https://cfg.test\n' > "$XDG/beaverhabits/env"
    run_bh list
    grep -Fq "https://habits.test/" "$CALL_LOG"
}

@test "the config file is parsed, never executed" {
    printf 'BEAVERHABITS_URL=$(touch %s/pwned)\ntouch %s/pwned2\n' "$TEST_DIR" "$TEST_DIR" > "$XDG/beaverhabits/env"
    run_cfg list
    [ "$status" -eq 1 ]
    [ ! -e "$TEST_DIR/pwned" ]
    [ ! -e "$TEST_DIR/pwned2" ]
}

@test "token is never printed nor passed as a command argument" {
    run_bh done "engl"
    [[ "$output$stderr" != *"$TOKEN"* ]]
    ! grep -Fq "$TOKEN" "$CALL_LOG"
}

@test "HTTP failure exits 3 with a message" {
    FAKE_CURL_FAIL=1 run_bh list
    [ "$status" -eq 3 ]
    [[ "$stderr" == *"request failed"* ]]
}

@test "unknown command exits 2" {
    run_bh nope
    [ "$status" -eq 2 ]
}

@test "report header shows the date and the progress" {
    NO_COLOR=1 run_bh report
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "Habits · Sat, Nov 21"*"1 of 3 done" ]]
    [[ "${lines[1]}" == *"33%" ]]
    [ "$(wc -l < "$CALL_LOG")" -eq 1 ]
}

@test "report shows the last 14 days in two weeks with weekday initials" {
    NO_COLOR=1 run_bh report
    [[ "$output" == *"S M T W T F S  S M T W T F S"* ]]
    [[ "$output" =~ "✓ Cat litter".+"· · · · · · ·  · · · · · · ●" ]]
    [[ "$output" =~ "○ English".+"· · · · · · ·  · · · · · ● ·" ]]
    [[ "$output" != *"Old"* ]]
}

@test "report streak counts consecutive days and keeps it while today is pending" {
    cat > "$TEST_DIR/export.json" <<'JSON'
{"habits": [
  {"id": "a", "name": "Read", "records": [
    {"day": "2026-11-21", "done": true, "timestamp": 1},
    {"day": "2026-11-20", "done": true, "timestamp": 1},
    {"day": "2026-11-19", "done": true, "timestamp": 1},
    {"day": "2026-11-17", "done": true, "timestamp": 1}]},
  {"id": "b", "name": "Run", "records": [
    {"day": "2026-11-20", "done": true, "timestamp": 1},
    {"day": "2026-11-19", "done": true, "timestamp": 1}]},
  {"id": "c", "name": "Meditate", "records": []}
]}
JSON
    NO_COLOR=1 run_bh report
    [[ "$output" =~ "Read".+"3 days" ]]
    [[ "$output" =~ "Run".+"2 days" ]]
    [[ "$output" =~ "Meditate".+"—" ]]
}

@test "report shows the days done in the last 7 days and the best streak" {
    cat > "$TEST_DIR/export.json" <<'JSON'
{"habits": [
  {"id": "a", "name": "Read", "records": [
    {"day": "2026-11-21", "done": true, "timestamp": 1},
    {"day": "2026-11-18", "done": true, "timestamp": 1},
    {"day": "2026-11-10", "done": true, "timestamp": 1},
    {"day": "2026-11-09", "done": true, "timestamp": 1},
    {"day": "2026-11-08", "done": true, "timestamp": 1},
    {"day": "2026-11-07", "done": true, "timestamp": 1}]}
]}
JSON
    NO_COLOR=1 run_bh report
    [[ "$output" == *"streak"*"7 days"*"best"* ]]
    [[ "$output" =~ "Read".+"1 day".+"2/7".+"4 days" ]]
}

@test "report colors the output unless NO_COLOR is set" {
    run_bh report
    [[ "$output" == *$'\e['* ]]
    NO_COLOR=1 run_bh report
    [[ "$output" != *$'\e['* ]]
}

@test "vicinae script commands declare the required directives and call the client" {
    local dir="$PROJECT_ROOT/configs/vicinae/scripts/beaverhabits" f
    for f in habits-today.sh habit-done.sh habit-undo.sh; do
        [ -x "$dir/$f" ]
        grep -Fqx '# @vicinae.schemaVersion 1' "$dir/$f"
        grep -Eq '^# @vicinae\.title .+' "$dir/$f"
        grep -Fq '/.dotfiles/bin/utils/beaverhabits' "$dir/$f"
    done
    grep -Eq '^# @vicinae\.argument1 \{.*"type": "text"' "$dir/habit-done.sh"
}

@test "links.conf links the vicinae scripts directory" {
    grep -Fqx 'configs/vicinae/scripts | .local/share/vicinae/scripts |' "$PROJECT_ROOT/configs/links.conf"
}
