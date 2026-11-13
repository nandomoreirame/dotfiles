#!/usr/bin/env bats


load '../../bats/helpers/setup'

setup() {
    ROOT="$PROJECT_ROOT"
    TEST_DIR="$(temp_make)"
    export HOME="$TEST_DIR/home" DOTFILES="$TEST_DIR/dotfiles"
    export DOTFILES_PRIVATE="$DOTFILES/private" LINKS_CONFIG="$DOTFILES/configs/links.conf"
    mkdir -p "$HOME" "$DOTFILES/configs"
    source "$ROOT/lib/links.sh"
}

teardown() {
    temp_del "$TEST_DIR"
}


@test "_parse_config_section: extracts items from section files" {
    local config_file="$TEST_DIR/test.conf"
    cat > "$config_file" << 'EOF'
[files]
.bashrc
.zshrc

[paths]
configs/bat|.config/bat
EOF

    run _parse_config_section "files" "$config_file"
    assert_success
    assert_output --partial ".bashrc"
    assert_output --partial ".zshrc"
    refute_output --partial "configs/bat"
}

@test "_parse_config_section: extracts items from section paths" {
    local config_file="$TEST_DIR/test.conf"
    cat > "$config_file" << 'EOF'
[files]
.bashrc
.zshrc

[paths]
configs/bat|.config/bat
configs/mise|.config/mise
EOF

    run _parse_config_section "paths" "$config_file"
    assert_success
    assert_output --partial "configs/bat"
    assert_output --partial "configs/mise"
    refute_output --partial ".bashrc"
}

@test "_parse_config_section: ignores comments" {
    local config_file="$TEST_DIR/test.conf"
    cat > "$config_file" << 'EOF'
[files]
.bashrc
.zshrc
EOF

    run _parse_config_section "files" "$config_file"
    assert_success
    assert_output --partial ".bashrc"
    assert_output --partial ".zshrc"
    refute_output --partial "comment"
}

@test "_parse_config_section: ignores blank lines" {
    local config_file="$TEST_DIR/test.conf"
    cat > "$config_file" << 'EOF'
[files]

.bashrc

.zshrc

EOF

    run _parse_config_section "files" "$config_file"
    assert_success
    assert_output --partial ".bashrc"
    assert_output --partial ".zshrc"
}

@test "_parse_config_section: returns empty for an absent section" {
    local config_file="$TEST_DIR/test.conf"
    cat > "$config_file" << 'EOF'
[files]
.bashrc
EOF

    run _parse_config_section "nonexistent" "$config_file"
    assert_success
    assert_output ""
}


@test "_load_files_from_config: returns empty when config is absent" {
    rm -f "$LINKS_CONFIG"

    _load_files_from_config

    [ "${#_files[@]}" -eq 0 ]
}

@test "_load_files_from_config: loads configured files" {
    mkdir -p "$(dirname "$LINKS_CONFIG")"
    cat > "$LINKS_CONFIG" << 'EOF'
[files]
.custom-file
.another-file
EOF

    _load_files_from_config

    [[ " ${_files[*]} " =~ " .custom-file " ]]
    [[ " ${_files[*]} " =~ " .another-file " ]]
}


@test "_load_paths_from_config: returns empty when config is absent" {
    rm -f "$LINKS_CONFIG"

    _load_paths_from_config

    [ ${#_paths[@]} -eq 0 ]
}

@test "_load_paths_from_config: loads configured paths" {
    mkdir -p "$(dirname "$LINKS_CONFIG")"
    cat > "$LINKS_CONFIG" << 'EOF'
[paths]
configs/custom|.config/custom
EOF

    _load_paths_from_config

    [[ " ${_paths[*]} " =~ "configs/custom" ]]
}


@test "_backup_or_remove_target: ignores absent targets" {
    local target="$TEST_DIR/nonexistent"

    run _backup_or_remove_target "$target"
    assert_success
    assert_output ""
}

@test "_backup_or_remove_target: removes existing symlinks" {
    local target="$TEST_DIR/link"
    local source="$TEST_DIR/source"
    touch "$source"
    ln -s "$source" "$target"

    run _backup_or_remove_target "$target"
    assert_success
    [ ! -L "$target" ]
}

@test "_backup_or_remove_target: backs up a real file" {
    local target="$TEST_DIR/real-file.txt"
    echo "content" > "$target"

    run _backup_or_remove_target "$target"
    assert_success
    assert_output --partial "Backup created"
    [ ! -f "$target" ]

    local backup_count
    backup_count=$(find "$TEST_DIR" -name "real-file.txt.bak.*" | wc -l)
    [ "$backup_count" -eq 1 ]
}

@test "_backup_or_remove_target: backs up a real directory" {
    local target="$TEST_DIR/real-dir"
    mkdir -p "$target"
    echo "content" > "$target/file.txt"

    run _backup_or_remove_target "$target"
    assert_success
    assert_output --partial "Backup created"
    [ ! -d "$target" ]

    local backup_count
    backup_count=$(find "$TEST_DIR" -maxdepth 1 -type d -name "real-dir.bak.*" | wc -l)
    [ "$backup_count" -eq 1 ]
}


@test "_link_files: links existing files" {
    mkdir -p "$DOTFILES/configs"
    echo "bashrc content" > "$DOTFILES/configs/.bashrc"
    echo "zshrc content" > "$DOTFILES/configs/.zshrc"

    mkdir -p "$(dirname "$LINKS_CONFIG")"
    cat > "$LINKS_CONFIG" << 'EOF'
[files]
.bashrc
.zshrc
EOF

    run env DOTFILES_YES=1 bash -c "source '$ROOT/lib/links.sh'; _link_files"
    assert_success

    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.zshrc" ]
    [ "$(readlink "$HOME/.bashrc")" = "$DOTFILES/configs/.bashrc" ]
    [ "$(readlink "$HOME/.zshrc")" = "$DOTFILES/configs/.zshrc" ]
}

@test "_link_paths: links existing paths" {
    mkdir -p "$DOTFILES/configs/bat"
    echo "bat config" > "$DOTFILES/configs/bat/config"

    mkdir -p "$(dirname "$LINKS_CONFIG")"
    cat > "$LINKS_CONFIG" << 'EOF'
[paths]
configs/bat/config|.config/bat/config
EOF

    run _link_paths
    assert_success

    [ -L "$HOME/.config/bat/config" ]
    [ "$(readlink "$HOME/.config/bat/config")" = "$DOTFILES/configs/bat/config" ]
}

@test "_link_paths: creates parent directories" {
    mkdir -p "$DOTFILES/configs/deep/nested"
    echo "config" > "$DOTFILES/configs/deep/nested/config"

    mkdir -p "$(dirname "$LINKS_CONFIG")"
    cat > "$LINKS_CONFIG" << 'EOF'
[paths]
configs/deep/nested/config|.config/deep/nested/config
EOF

    run _link_paths
    assert_success

    assert_dir_exists "$HOME/.config/deep/nested"
    [ -L "$HOME/.config/deep/nested/config" ]
    [ "$(readlink "$HOME/.config/deep/nested/config")" = "$DOTFILES/configs/deep/nested/config" ]
}

@test "_link_files: skips absent files after confirmation" {
    mkdir -p "$DOTFILES/configs"
    echo "bashrc content" > "$DOTFILES/configs/.bashrc"

    mkdir -p "$(dirname "$LINKS_CONFIG")"
    cat > "$LINKS_CONFIG" << 'EOF'
[files]
.bashrc
.zshrc
EOF

    run env DOTFILES_YES=1 bash -c "source '$ROOT/lib/links.sh'; _link_files"
    assert_success
    assert_output --partial "Skipping .zshrc"

    [ -L "$HOME/.bashrc" ]
    [ "$(readlink "$HOME/.bashrc")" = "$DOTFILES/configs/.bashrc" ]
}

@test "links reads the private links.conf after the public one" {
    export DOTFILES="$BATS_TEST_TMPDIR/dot" HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES_PRIVATE="$DOTFILES/private" LINKS_CONFIG="$DOTFILES/configs/links.conf"
    mkdir -p "$DOTFILES/configs" "$DOTFILES/private/espanso" "$HOME"
    printf '[paths]\n' > "$DOTFILES/configs/links.conf"
    echo x > "$DOTFILES/private/espanso/personal.yml"
    printf '[paths]\nprivate/espanso/personal.yml | .config/espanso/match/personal.yml |\n' > "$DOTFILES/private/links.conf"
    run bash -c "source '$ROOT/lib/links.sh'; _load_paths_from_config; printf '%s\n' \"\${_paths[@]}\""
    [[ "$output" == *"private/espanso/personal.yml"* ]]
    run bash -c "source '$ROOT/lib/links.sh'; _link_paths"
    [ -L "$HOME/.config/espanso/match/personal.yml" ]
}

@test "a private entry for the same target replaces the public one" {
    export DOTFILES="$BATS_TEST_TMPDIR/dot" HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES_PRIVATE="$DOTFILES/private" LINKS_CONFIG="$DOTFILES/configs/links.conf"
    mkdir -p "$DOTFILES/configs/x" "$DOTFILES/private/x" "$HOME"
    echo pub > "$DOTFILES/configs/x/c"; echo priv > "$DOTFILES/private/x/c"
    printf '[paths]\nconfigs/x/c | .config/x/c |\n' > "$DOTFILES/configs/links.conf"
    printf '[paths]\nprivate/x/c | .config/x/c |\n' > "$DOTFILES/private/links.conf"
    run bash -c "source '$ROOT/lib/links.sh'; _link_paths"
    [ "$(cat "$HOME/.config/x/c")" = "priv" ]
}

@test "a missing private links.conf is silent" {
    export DOTFILES="$BATS_TEST_TMPDIR/dot" HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES_PRIVATE="$DOTFILES/private" LINKS_CONFIG="$DOTFILES/configs/links.conf"
    mkdir -p "$DOTFILES/configs" "$HOME"
    printf '[paths]\n' > "$DOTFILES/configs/links.conf"
    run bash -c "source '$ROOT/lib/links.sh'; _link_paths"
    [[ "$output" != *"private"* ]]
}

@test "linking twice is idempotent" {
    export DOTFILES="$BATS_TEST_TMPDIR/dot" HOME="$BATS_TEST_TMPDIR/home"
    export DOTFILES_PRIVATE="$DOTFILES/private" LINKS_CONFIG="$DOTFILES/configs/links.conf"
    mkdir -p "$DOTFILES/configs/x" "$HOME"; echo a > "$DOTFILES/configs/x/c"
    printf '[paths]\nconfigs/x/c | .config/x/c |\n' > "$DOTFILES/configs/links.conf"
    bash -c "source '$ROOT/lib/links.sh'; _link_paths" >/dev/null
    run bash -c "source '$ROOT/lib/links.sh'; _link_paths"
    [ "$status" -eq 0 ]
    [ -L "$HOME/.config/x/c" ]
    [ -z "$(ls "$HOME"/.config/x/ | grep -v '^c$')" ]
}

@test "the public links.conf ships documented and empty" {
    run grep -vE '^\s*(#|$|\[)' "$ROOT/configs/links.conf"
    [ -z "$output" ]
    grep -q "\[paths:arch\]" "$ROOT/configs/links.conf"
}

@test "invalid target traversal leaves HOME untouched" {
    echo data > "$DOTFILES/configs/source"
    printf '[paths]\nconfigs/source | ../escaped |\n' > "$LINKS_CONFIG"
    run _link_paths
    [ "$status" -ne 0 ]
    [ ! -e "$TEST_DIR/escaped" ]
}

@test "an external overlay source resolves through DOTFILES_PRIVATE" {
    export DOTFILES_PRIVATE="$TEST_DIR/overlay"
    mkdir -p "$DOTFILES_PRIVATE"
    echo data > "$DOTFILES_PRIVATE/source"
    printf '[paths]\nprivate/source | .external |\n' > "$DOTFILES_PRIVATE/links.conf"
    printf '[paths]\n' > "$LINKS_CONFIG"
    run _link_paths
    [ "$status" -eq 0 ]
    [ "$(readlink "$HOME/.external")" = "$DOTFILES_PRIVATE/source" ]
}
