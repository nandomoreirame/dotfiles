#!/usr/bin/env bats

# Unit tests for bin/utils/clean-claude-sessions
#
# Run:
#   ./tests/run-tests unit/bin/clean-claude-sessions.bats
#
# Coverage:
#   - Argument parsing (--dry-run, --all, --yes, --help, positional DAYS)
#   - Invalid argument validation
#   - Missing projects directory
#   - Old session detection by internal JSONL timestamp
#   - Dry-run: no files removed, no confirmation asked
#   - Real removal with --yes: files and subagent dirs deleted
#   - sessions-index.json cleanup
#   - Scope: current dir only (default) vs --all
#   - Confirmation prompt (--yes skips, default blocks)
#   - Session listing output (project path, name/id, date)
#   - Summary output (counts and size)
#   - Combined flags

load '../../bats/helpers/setup'

# ---------------------------------------------------------------------------
# Setup / Teardown
# ---------------------------------------------------------------------------

setup() {
    TEST_DIR="$(temp_make)"
    SCRIPT="$PROJECT_ROOT/bin/utils/clean-claude-sessions"

    export HOME="$TEST_DIR"

    PROJECTS_DIR="$TEST_DIR/.claude/projects"
    mkdir -p "$PROJECTS_DIR"
}

teardown() {
    temp_del "$TEST_DIR"
}

# ---------------------------------------------------------------------------
# Helper: create a .jsonl file with given timestamp and optional slug
# ---------------------------------------------------------------------------

_make_session_file() {
    local filepath="$1"
    local timestamp="$2"
    local slug="${3:-}"

    if [[ -n "$slug" ]]; then
        cat > "$filepath" << EOF
{"type":"user","timestamp":"${timestamp}","slug":"${slug}","message":{"content":"hello"}}
{"type":"assistant","timestamp":"${timestamp}","slug":"${slug}","message":{"content":"world"}}
EOF
    else
        cat > "$filepath" << EOF
{"type":"user","timestamp":"${timestamp}","message":{"content":"hello"}}
{"type":"assistant","timestamp":"${timestamp}","message":{"content":"world"}}
EOF
    fi
}

# ---------------------------------------------------------------------------
# Helper: create a full session project
# ---------------------------------------------------------------------------

_make_project() {
    local project_name="$1"
    local session_id="$2"
    local timestamp="$3"
    local slug="${4:-}"

    local project_dir="$PROJECTS_DIR/$project_name"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${session_id}.jsonl" "$timestamp" "$slug"
    echo "$project_dir/${session_id}.jsonl"
}

# ---------------------------------------------------------------------------
# Helper: ISO UTC date N days ago
# ---------------------------------------------------------------------------

_days_ago() {
    local days="$1"
    python3 -c "
from datetime import datetime, timedelta, timezone
dt = datetime.now(timezone.utc) - timedelta(days=$days)
print(dt.strftime('%Y-%m-%dT%H:%M:%S.000Z'))
"
}

# ============================================
# --help / -h
# ============================================

@test "--help: shows usage message" {
    run bash "$SCRIPT" --help
    assert_success
    assert_output --partial "clean-claude-sessions"
    assert_output --partial "--dry-run"
    assert_output --partial "--all"
    assert_output --partial "--yes"
}

@test "-h: shows usage message (alias)" {
    run bash "$SCRIPT" -h
    assert_success
    assert_output --partial "clean-claude-sessions"
}

# ============================================
# Invalid argument validation
# ============================================

@test "unknown flag: returns error and exit 1" {
    run bash "$SCRIPT" --invalid-flag
    assert_failure
    assert_output --partial "unknown option"
}

@test "non-numeric positional arg: returns error" {
    run bash "$SCRIPT" abc
    assert_failure
    assert_output --partial "invalid argument"
}

# ============================================
# Missing projects directory
# ============================================

@test "missing ~/.claude/projects: exits without error" {
    rm -rf "$PROJECTS_DIR"
    # Need to also handle the scope resolution - use --all to skip pwd check
    run bash "$SCRIPT" --all
    assert_success
    assert_output --partial "claude projects directory not found"
}

# ============================================
# Scope: current dir only (default)
# ============================================

@test "default scope: only processes current directory project" {
    local cwd_name
    cwd_name=$(pwd -P | sed 's|/$||; s|/|-|g')

    local id_current="aaaaaaaa-a001-a001-a001-000000000001"
    local id_other="bbbbbbbb-a002-a002-a002-000000000002"

    _make_project "$cwd_name" "$id_current" "$(_days_ago 45)"
    _make_project "-srv-example-otherproj" "$id_other" "$(_days_ago 45)"

    run bash "$SCRIPT" --dry-run
    assert_success
    assert_output --partial "${id_current:0:8}"
    refute_output --partial "${id_other:0:8}"
}

@test "default scope: no sessions for pwd shows warning" {
    # pwd won't match any project in temp dir
    local fake_dir="$PROJECTS_DIR/-this-does-not-exist"
    # Don't create it

    run bash "$SCRIPT"
    assert_success
    assert_output --partial "no sessions found for current directory"
    assert_output --partial "--all"
}

@test "--all: processes all projects" {
    local id1="cccccccc-a003-a003-a003-000000000003"
    local id2="dddddddd-a004-a004-a004-000000000004"

    _make_project "-srv-example-projA" "$id1" "$(_days_ago 45)"
    _make_project "-srv-example-projB" "$id2" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "${id1:0:8}"
    assert_output --partial "${id2:0:8}"
}

# ============================================
# No old sessions found
# ============================================

@test "no old sessions: shows 'no sessions' message" {
    local session_id="eeeeeeee-a005-a005-a005-000000000005"
    _make_project "-srv-example-recent" "$session_id" "$(_days_ago 1)"

    run bash "$SCRIPT" --all
    assert_success
    assert_output --partial "no sessions older than"
}

# ============================================
# Old session detection
# ============================================

@test "session 31 days old: detected as old" {
    local session_id="ffffffff-a006-a006-a006-000000000006"
    _make_project "-srv-example-old" "$session_id" "$(_days_ago 31)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "${session_id:0:8}"
}

@test "session 29 days 23 hours: not detected (within threshold)" {
    local session_id="11111111-a007-a007-a007-000000000007"
    local ts
    ts=$(python3 -c "
from datetime import datetime, timedelta, timezone
dt = datetime.now(timezone.utc) - timedelta(days=29, hours=23)
print(dt.strftime('%Y-%m-%dT%H:%M:%S.000Z'))
")
    local project_dir="$PROJECTS_DIR/-srv-example-edge"
    mkdir -p "$project_dir"
    _make_session_file "$project_dir/${session_id}.jsonl" "$ts"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    refute_output --partial "${session_id:0:8}"
}

@test "session 29 days old with threshold 30: not detected" {
    local session_id="22222222-a008-a008-a008-000000000008"
    _make_project "-srv-example-recent2" "$session_id" "$(_days_ago 29)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "no sessions older than"
}

# ============================================
# Positional DAYS argument
# ============================================

@test "positional 7: session 8 days old is detected" {
    local session_id="33333333-a009-a009-a009-000000000009"
    _make_project "-srv-example-days7" "$session_id" "$(_days_ago 8)"

    run bash "$SCRIPT" --all --dry-run 7
    assert_success
    assert_output --partial "${session_id:0:8}"
}

@test "positional 7: session 6 days old is not detected" {
    local session_id="44444444-a010-a010-a010-000000000010"
    _make_project "-srv-example-days7r" "$session_id" "$(_days_ago 6)"

    run bash "$SCRIPT" --all --dry-run 7
    assert_success
    assert_output --partial "no sessions older than"
}

@test "positional 60: session 31 days old is not detected" {
    local session_id="55555555-a011-a011-a011-000000000011"
    _make_project "-srv-example-days60" "$session_id" "$(_days_ago 31)"

    run bash "$SCRIPT" --all --dry-run 60
    assert_success
    assert_output --partial "no sessions older than"
}

# ============================================
# Session listing output
# ============================================

@test "listing: shows project path as readable path" {
    local session_id="66666666-a012-a012-a012-000000000012"
    _make_project "-srv-example-myproject" "$session_id" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "/srv/example/myproject"
}

@test "listing: shows session slug when available" {
    local session_id="77777777-a013-a013-a013-000000000013"
    _make_project "-srv-example-slugtest" "$session_id" "$(_days_ago 45)" "golden-waddling-brooks"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "golden-waddling-brooks"
}

@test "listing: shows truncated session ID" {
    local session_id="88888888-a014-a014-a014-000000000014"
    _make_project "-srv-example-idtest" "$session_id" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "88888888..."
}

@test "listing: shows date in YYYY-MM-DD HH:MM format" {
    local session_id="99999999-a015-a015-a015-000000000015"
    _make_project "-srv-example-datetest" "$session_id" "2026-01-15T10:30:00.000Z"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "2026-01-15"
}

# ============================================
# --dry-run: no files removed
# ============================================

@test "--dry-run: .jsonl file preserved after execution" {
    local session_id="aaaaaaaa-a016-a016-a016-000000000016"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-dryrun" "$session_id" "$(_days_ago 45)")"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_file_exists "$jsonl_file"
}

@test "--dry-run: shows 'dry-run complete' message" {
    local session_id="bbbbbbbb-a017-a017-a017-000000000017"
    _make_project "-srv-example-dryrun2" "$session_id" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "dry-run complete"
}

# ============================================
# Confirmation prompt
# ============================================

@test "confirmation: 'n' cancels deletion" {
    local session_id="cccccccc-a018-a018-a018-000000000018"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-confirm" "$session_id" "$(_days_ago 45)")"

    run bash -c "echo 'n' | bash '$SCRIPT' --all"
    assert_success
    assert_output --partial "cancelled by user"
    assert_file_exists "$jsonl_file"
}

@test "confirmation: empty input cancels deletion" {
    local session_id="dddddddd-a019-a019-a019-000000000019"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-confirm2" "$session_id" "$(_days_ago 45)")"

    run bash -c "echo '' | bash '$SCRIPT' --all"
    assert_success
    assert_output --partial "cancelled by user"
    assert_file_exists "$jsonl_file"
}

@test "--yes: skips confirmation and deletes" {
    local session_id="eeeeeeee-a020-a020-a020-000000000020"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-yesmode" "$session_id" "$(_days_ago 45)")"

    run bash "$SCRIPT" --all --yes
    assert_success
    assert_output --partial "CLEANUP COMPLETE"
    assert_file_not_exists "$jsonl_file"
}

@test "-y: alias for --yes works" {
    local session_id="ffffffff-a021-a021-a021-000000000021"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-yalias" "$session_id" "$(_days_ago 45)")"

    run bash "$SCRIPT" --all -y
    assert_success
    assert_file_not_exists "$jsonl_file"
}

# ============================================
# Real removal with --yes
# ============================================

@test "removal: .jsonl file is deleted" {
    local session_id="11111111-a022-a022-a022-000000000022"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-remove" "$session_id" "$(_days_ago 45)")"

    run bash "$SCRIPT" --all --yes
    assert_success
    assert_file_not_exists "$jsonl_file"
}

@test "removal: subagent directory is deleted" {
    local session_id="22222222-a023-a023-a023-000000000023"
    local project_dir="$PROJECTS_DIR/-srv-example-subagent"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${session_id}.jsonl" "$(_days_ago 45)"

    local subagent_dir="$project_dir/$session_id"
    mkdir -p "$subagent_dir"
    echo "subagent data" > "$subagent_dir/data.json"

    run bash "$SCRIPT" --all --yes
    assert_success
    assert_file_not_exists "$project_dir/${session_id}.jsonl"
    assert_dir_not_exists "$subagent_dir"
}

@test "removal: recent session is not touched" {
    local old_id="33333333-a024-a024-a024-000000000024"
    local new_id="44444444-a025-a025-a025-000000000025"
    local project_dir="$PROJECTS_DIR/-srv-example-mixed"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${old_id}.jsonl" "$(_days_ago 45)"
    _make_session_file "$project_dir/${new_id}.jsonl" "$(_days_ago 5)"

    run bash "$SCRIPT" --all --yes
    assert_success
    assert_file_not_exists "$project_dir/${old_id}.jsonl"
    assert_file_exists "$project_dir/${new_id}.jsonl"
}

# ============================================
# sessions-index.json cleanup
# ============================================

@test "sessions-index.json: entry removed after cleanup" {
    local session_id="55555555-a026-a026-a026-000000000026"
    local project_dir="$PROJECTS_DIR/-srv-example-index"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${session_id}.jsonl" "$(_days_ago 45)"

    cat > "$project_dir/sessions-index.json" << EOF
{
  "entries": [
    {"sessionId": "${session_id}", "projectPath": "/srv/example/myproject"},
    {"sessionId": "keep-this-one", "projectPath": "/srv/example/other"}
  ]
}
EOF

    run bash "$SCRIPT" --all --yes
    assert_success

    run python3 -c "
import json
with open('$project_dir/sessions-index.json') as f:
    data = json.load(f)
ids = [e['sessionId'] for e in data['entries']]
assert '${session_id}' not in ids, 'session still in index'
assert 'keep-this-one' in ids, 'other session was removed'
print('ok')
"
    assert_success
    assert_output --partial "ok"
}

@test "--dry-run: sessions-index.json is not modified" {
    local session_id="66666666-a027-a027-a027-000000000027"
    local project_dir="$PROJECTS_DIR/-srv-example-index-dry"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${session_id}.jsonl" "$(_days_ago 45)"

    local index_content
    index_content='{"entries":[{"sessionId":"'"${session_id}"'","projectPath":"/srv/example/x"}]}'
    echo "$index_content" > "$project_dir/sessions-index.json"

    run bash "$SCRIPT" --all --dry-run
    assert_success

    run python3 -c "
import json
with open('$project_dir/sessions-index.json') as f:
    data = json.load(f)
ids = [e['sessionId'] for e in data['entries']]
assert '${session_id}' in ids, 'session was removed from index in dry-run'
print('ok')
"
    assert_success
    assert_output --partial "ok"
}

@test "sessions-index.json: file mode is preserved" {
    local session_id="55555555-a026-a026-a026-000000000027"
    local project_dir="$PROJECTS_DIR/-srv-example-mode"
    mkdir -p "$project_dir"
    _make_session_file "$project_dir/${session_id}.jsonl" "$(_days_ago 45)"
    cat > "$project_dir/sessions-index.json" << EOF
{"entries": [{"sessionId": "${session_id}"}, {"sessionId": "keep-this-one"}]}
EOF
    chmod 644 "$project_dir/sessions-index.json"

    run bash "$SCRIPT" --all --yes
    assert_success

    run stat -c '%a' "$project_dir/sessions-index.json"
    assert_output "644"
}

@test "sessions-index.json absent: no error" {
    local session_id="77777777-a028-a028-a028-000000000028"
    local project_dir="$PROJECTS_DIR/-srv-example-noindex"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${session_id}.jsonl" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --yes
    assert_success
    assert_file_not_exists "$project_dir/${session_id}.jsonl"
}

@test "sessions-index.json: second run is a byte-identical no-op" {
    local session_id="abababab-a040-a040-a040-000000000040"
    local keep_id="cdcdcdcd-a041-a041-a041-000000000041"
    local project_dir="$PROJECTS_DIR/-srv-example-index-idem"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${session_id}.jsonl" "$(_days_ago 45)"
    _make_session_file "$project_dir/${keep_id}.jsonl" "$(_days_ago 1)"

    cat > "$project_dir/sessions-index.json" << EOF
{
  "entries": [
    {"sessionId": "${session_id}", "projectPath": "/srv/example/old"},
    {"sessionId": "${keep_id}", "projectPath": "/srv/example/keep"}
  ]
}
EOF

    run bash "$SCRIPT" --all --yes
    assert_success
    local sum1
    sum1="$(md5sum "$project_dir/sessions-index.json" | cut -d' ' -f1)"

    run bash "$SCRIPT" --all --yes
    assert_success
    local sum2
    sum2="$(md5sum "$project_dir/sessions-index.json" | cut -d' ' -f1)"
    [ "$sum1" = "$sum2" ]
}

@test "sessions-index.json: unknown top-level keys and entry fields survive" {
    local session_id="efefefef-a042-a042-a042-000000000042"
    local keep_id="f0f0f0f0-a043-a043-a043-000000000043"
    local project_dir="$PROJECTS_DIR/-srv-example-index-tolerant"
    mkdir -p "$project_dir"

    _make_session_file "$project_dir/${session_id}.jsonl" "$(_days_ago 45)"
    _make_session_file "$project_dir/${keep_id}.jsonl" "$(_days_ago 1)"

    cat > "$project_dir/sessions-index.json" << EOF
{
  "version": 2,
  "customNote": "preserve-me-do-not-delete",
  "entries": [
    {"sessionId": "${session_id}", "projectPath": "/srv/example/old", "extra": "gone-with-row"},
    {"sessionId": "${keep_id}", "projectPath": "/srv/example/keep", "extraField": "still-here", "label": "keep-extra"}
  ]
}
EOF

    run bash "$SCRIPT" --all --yes
    assert_success

    run python3 -c "
import json
with open('$project_dir/sessions-index.json') as f:
    data = json.load(f)
assert data.get('version') == 2, data
assert data.get('customNote') == 'preserve-me-do-not-delete', data
ids = [e['sessionId'] for e in data['entries']]
assert '${session_id}' not in ids
assert '${keep_id}' in ids
kept = next(e for e in data['entries'] if e['sessionId'] == '${keep_id}')
assert kept.get('extraField') == 'still-here', kept
assert kept.get('label') == 'keep-extra', kept
print('ok')
"
    assert_success
    assert_output --partial "ok"
}

# ============================================
# Summary output
# ============================================

@test "summary: shows session count" {
    local id1="88888888-a029-a029-a029-000000000029"
    local id2="99999999-a030-a030-a030-000000000030"
    _make_project "-srv-example-sum1" "$id1" "$(_days_ago 45)"
    _make_project "-srv-example-sum2" "$id2" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "Sessions"
    assert_output --partial "2"
}

@test "summary: shows project count" {
    local id1="aaaaaaaa-a031-a031-a031-000000000031"
    local id2="bbbbbbbb-a032-a032-a032-000000000032"

    _make_project "-srv-example-projA" "$id1" "$(_days_ago 45)"
    _make_project "-srv-example-projB" "$id2" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "Projects"
    assert_output --partial "2"
}

@test "summary: shows day threshold" {
    local session_id="cccccccc-a033-a033-a033-000000000033"
    _make_project "-srv-example-age" "$session_id" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run 15
    assert_success
    assert_output --partial "15"
}

@test "summary: shows scope label" {
    local session_id="dddddddd-a034-a034-a034-000000000034"
    _make_project "-srv-example-scope" "$session_id" "$(_days_ago 45)"

    run bash "$SCRIPT" --all --dry-run
    assert_success
    assert_output --partial "all projects"
}

# ============================================
# Combined flags
# ============================================

@test "--dry-run with positional days: works correctly" {
    local session_id="eeeeeeee-a035-a035-a035-000000000035"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-combo" "$session_id" "$(_days_ago 10)")"

    run bash "$SCRIPT" --all --dry-run 7
    assert_success
    assert_file_exists "$jsonl_file"
    assert_output --partial "${session_id:0:8}"
}

@test "--all --yes with positional days: deletes correctly" {
    local id_old="ffffffff-a036-a036-a036-000000000036"
    local id_recent="11111111-a037-a037-a037-000000000037"

    local file_old file_recent
    file_old="$(_make_project "-srv-example-allyesdays" "$id_old" "$(_days_ago 20)")"
    file_recent="$(_make_project "-srv-example-allyesdays" "$id_recent" "$(_days_ago 5)")"

    run bash "$SCRIPT" --all --yes 10
    assert_success
    assert_output --partial "CLEANUP COMPLETE"
    assert_file_not_exists "$file_old"
    assert_file_exists "$file_recent"
}

@test "confirmation 'y': proceeds with deletion" {
    local session_id="22222222-a038-a038-a038-000000000038"
    local jsonl_file
    jsonl_file="$(_make_project "-srv-example-yesconfirm" "$session_id" "$(_days_ago 45)")"

    run bash -c "echo 'y' | bash '$SCRIPT' --all"
    assert_success
    assert_output --partial "CLEANUP COMPLETE"
    assert_file_not_exists "$jsonl_file"
}
