#!/usr/bin/env bats

# Unit tests for bin/utils/noctalia-plugins-link
#
# Run:
#   ./tests/run-tests unit/bin/noctalia-plugins-link.bats
#
# Links v5-ready <name> repos (one dir per plugin) into XDG_DATA_HOME/noctalia/plugins/<name>.
# Uses temp dirs via NOCTALIA_PLUGIN_REPOS_DIR and XDG_DATA_HOME; never touches real paths.

load '../../bats/helpers/setup'
bats_require_minimum_version 1.5.0

SCRIPT="$PROJECT_ROOT/bin/utils/noctalia-plugins-link"

setup() {
    export NOCTALIA_PLUGIN_AUTHOR="${NOCTALIA_PLUGIN_AUTHOR:-jane}"
    TEST_DIR="$(temp_make)"
    REPOS_DIR="$TEST_DIR/noctalia-plugins"
    DATA_HOME="$TEST_DIR/xdg-data"
    PLUGINS_DIR="$DATA_HOME/noctalia/plugins"
    mkdir -p "$REPOS_DIR"
}

teardown() {
    temp_del "$TEST_DIR"
}

run_link() {
    local separate=()
    if [ "${1:-}" = "--separate-stderr" ]; then
        separate=(--separate-stderr)
        shift
    fi
    run "${separate[@]}" env \
        NOCTALIA_PLUGIN_REPOS_DIR="$REPOS_DIR" \
        XDG_DATA_HOME="$DATA_HOME" \
        NOCTALIA_PLUGIN_AUTHOR="${NOCTALIA_PLUGIN_AUTHOR:-jane}" \
        bash "$SCRIPT" "$@"
}

# Create a v5-ready plugin repo: <name> with matching plugin.toml id.
make_v5_repo() {
    local name="$1"
    local id="${2:-jane/${name}}"
    local repo="$REPOS_DIR/${name}"
    mkdir -p "$repo"
    printf 'id = "%s"\nname = "%s"\nversion = "0.1.0"\n' "$id" "$name" >"$repo/plugin.toml"
}

# Create a QML (v4) repo: <name> without plugin.toml.
make_qml_repo() {
    local name="$1"
    local repo="$REPOS_DIR/${name}"
    mkdir -p "$repo/components"
    printf '{ "name": "%s" }\n' "$name" >"$repo/manifest.json"
}

@test "script exists and is executable" {
    assert_file_exist "$SCRIPT"
    [[ -x "$SCRIPT" ]]
}

@test "symlinks v5-ready repo <name> into plugins/<name>" {
    make_v5_repo "aibar"

    run_link
    assert_success

    assert_symlink_to "$REPOS_DIR/aibar" "$PLUGINS_DIR/aibar"
}

@test "link name is the plugin directory name (desktop-sticky-notes)" {
    make_v5_repo "desktop-sticky-notes"

    run_link
    assert_success

    assert_symlink_to "$REPOS_DIR/desktop-sticky-notes" "$PLUGINS_DIR/desktop-sticky-notes"
}

@test "skips QML repos without root plugin.toml" {
    make_qml_repo "aibar"
    make_v5_repo "daybar"

    run_link
    assert_success

    assert_file_not_exist "$PLUGINS_DIR/aibar"
    assert_symlink_to "$REPOS_DIR/daybar" "$PLUGINS_DIR/daybar"
}

@test "skips when plugin.toml id does not match jane/<name>" {
    make_v5_repo "aibar" "wrong/aibar"

    run_link --separate-stderr
    assert_success

    assert_file_not_exist "$PLUGINS_DIR/aibar"
    [[ "$stderr" == *"id"* || "$output" == *"id"* ]]
    [[ "$output" == *"skipped aibar"* ]]
}

@test "creates plugins target directory when missing" {
    make_v5_repo "gistbar"
    [[ ! -d "$PLUGINS_DIR" ]]

    run_link
    assert_success

    assert_dir_exist "$PLUGINS_DIR"
    assert_symlink_to "$REPOS_DIR/gistbar" "$PLUGINS_DIR/gistbar"
}

@test "replaces a stale symlink that points elsewhere" {
    make_v5_repo "aibar"
    mkdir -p "$PLUGINS_DIR" "$TEST_DIR/elsewhere"
    ln -s "$TEST_DIR/elsewhere" "$PLUGINS_DIR/aibar"

    run_link
    assert_success

    assert_symlink_to "$REPOS_DIR/aibar" "$PLUGINS_DIR/aibar"
}

@test "leaves a correct symlink as is" {
    make_v5_repo "aibar"
    mkdir -p "$PLUGINS_DIR"
    ln -s "$REPOS_DIR/aibar" "$PLUGINS_DIR/aibar"
    local before
    before="$(readlink "$PLUGINS_DIR/aibar")"

    run_link
    assert_success

    assert_equal "$(readlink "$PLUGINS_DIR/aibar")" "$before"
    assert_symlink_to "$REPOS_DIR/aibar" "$PLUGINS_DIR/aibar"
}

@test "never deletes or replaces a real directory; warns and skips" {
    make_v5_repo "aibar"
    mkdir -p "$PLUGINS_DIR/aibar"
    printf 'keep\n' >"$PLUGINS_DIR/aibar/important.txt"

    run_link --separate-stderr
    assert_success

    assert_file_exist "$PLUGINS_DIR/aibar/important.txt"
    [[ ! -L "$PLUGINS_DIR/aibar" ]]
    [[ "$stderr" == *"aibar"* || "$output" == *"aibar"* ]]
    [[ "$output" == *"skipped aibar"* ]]
}

@test "never deletes or replaces a real file; warns and skips" {
    make_v5_repo "daybar"
    mkdir -p "$PLUGINS_DIR"
    printf 'not a plugin\n' >"$PLUGINS_DIR/daybar"

    run_link --separate-stderr
    assert_success

    assert_file_exist "$PLUGINS_DIR/daybar"
    [[ ! -L "$PLUGINS_DIR/daybar" ]]
    [[ "$output" == *"skipped daybar"* ]]
}

@test "--list prints unlinked/skipped without creating symlinks" {
    make_v5_repo "aibar"
    make_qml_repo "daybar"
    make_v5_repo "gistbar" "other/gistbar"

    run_link --list
    assert_success
    assert_equal "$status" 0

    [[ "$output" == *"unlinked aibar: run noctalia-plugins-link"* ]]
    [[ "$output" == *"skipped daybar:"* ]]
    [[ "$output" == *"skipped gistbar:"* ]]
    assert_file_not_exist "$PLUGINS_DIR/aibar"
    [[ ! -e "$PLUGINS_DIR" ]] || [[ -z "$(find "$PLUGINS_DIR" -mindepth 1 2>/dev/null)" ]]
}

@test "--list on v5-ready repo with no symlink creates nothing and prints unlinked" {
    make_v5_repo "aibar"

    run_link --list
    assert_success

    [[ "$output" == *"unlinked aibar: run noctalia-plugins-link"* ]]
    [[ "$output" != *"linked aibar ->"* ]]
    assert_file_not_exist "$PLUGINS_DIR/aibar"
}

@test "--list after default run prints linked" {
    make_v5_repo "aibar"

    run_link
    assert_success
    assert_symlink_to "$REPOS_DIR/aibar" "$PLUGINS_DIR/aibar"

    run_link --list
    assert_success

    [[ "$output" == *"linked aibar ->"* ]]
    [[ "$output" != *"unlinked aibar"* ]]
}

@test "default run also prints linked/skipped status lines" {
    make_v5_repo "aibar"
    make_qml_repo "daybar"

    run_link
    assert_success

    [[ "$output" == *"linked aibar ->"* ]]
    [[ "$output" == *"skipped daybar:"* ]]
}

@test "ignores v4 worktrees (-v4) and backups (.bak) without listing them" {
    make_v5_repo "aibar"
    mkdir -p "$REPOS_DIR/aibar-v4" "$REPOS_DIR/aibar-v4.bak"
    printf 'id = "jane/aibar-v4"\n' >"$REPOS_DIR/aibar-v4/plugin.toml"

    run_link --list
    assert_success
    [[ "$output" != *"aibar-v4"* ]]

    run_link
    assert_success
    assert_file_not_exist "$PLUGINS_DIR/aibar-v4"
    assert_file_not_exist "$PLUGINS_DIR/aibar-v4.bak"
    assert_symlink_to "$REPOS_DIR/aibar" "$PLUGINS_DIR/aibar"
}

@test "defaults to ~/hub/projects/noctalia-plugins" {
    run grep -F '${HOME}/hub/projects/noctalia-plugins' "$SCRIPT"
    assert_success
}


@test "noctalia-plugins-link does nothing without the plugin author" {
    run env -i HOME="$BATS_TEST_TMPDIR" PATH="/usr/bin:/bin" bash "$PROJECT_ROOT/bin/utils/noctalia-plugins-link" --list
    [ "$status" -ne 0 ]
    [[ "$output$stderr" == *"NOCTALIA_PLUGIN_AUTHOR"* ]]
}
