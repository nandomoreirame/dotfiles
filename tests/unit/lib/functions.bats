#!/usr/bin/env bats


load '../../bats/helpers/setup'

setup() {
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    source "$PROJECT_ROOT/lib/functions.sh"
    TEST_DIR="$(temp_make)"
}

teardown() {
    temp_del "$TEST_DIR"
}


@test "e_success prints a success message" {
    run e_success "Test message"
    assert_success
    assert_output --partial "✔"
    assert_output --partial "Test message"
}

@test "e_error: prints an error message" {
    run e_error "Error message"
    assert_success
    assert_output --partial "✖"
    assert_output --partial "Error message"
}

@test "e_info: prints an info message" {
    run e_info "Info message"
    assert_success
    assert_output --partial "ℹ"
    assert_output --partial "Info message"
}

@test "e_warning: prints a warning message" {
    run e_warning "Warning message"
    assert_success
    assert_output --partial "➜"
    assert_output --partial "Warning message"
}

@test "e_arrow: prints an arrow message" {
    run e_arrow "Arrow message"
    assert_success
    assert_output --partial "➜"
    assert_output --partial "Arrow message"
}

@test "e_header: prints a formatted header" {
    run e_header "Header Title"
    assert_success
    assert_output --partial "=========="
    assert_output --partial "Header Title"
}

@test "e_bold: prints bold text" {
    run e_bold "Bold text"
    assert_success
    assert_output --partial "Bold text"
}

@test "e_underline: prints underlined text" {
    run e_underline "Underlined text"
    assert_success
    assert_output --partial "Underlined text"
}

@test "e_note: prints a formatted note" {
    run e_note "Note message"
    assert_success
    assert_output --partial "Note:"
    assert_output --partial "Note message"
}


@test "mkd: creates a directory and succeeds" {
    local new_dir="$TEST_DIR/new-directory"

    run bash -c "source '$PROJECT_ROOT/lib/functions.sh' && mkd '$new_dir' && pwd"
    assert_success
    assert_output "$new_dir"
    assert_dir_exists "$new_dir"
}

@test "mkd: creates nested directories" {
    local nested_dir="$TEST_DIR/level1/level2/level3"

    run bash -c "source '$PROJECT_ROOT/lib/functions.sh' && mkd '$nested_dir' && pwd"
    assert_success
    assert_output "$nested_dir"
    assert_dir_exists "$nested_dir"
}


@test "fs: returns a file size" {
    local test_file="$TEST_DIR/test-file.txt"
    echo "Hello World" > "$test_file"

    run fs "$test_file"
    assert_success
    assert_output --partial "$test_file"
}

@test "fs: returns a directory size" {
    mkdir -p "$TEST_DIR/subdir"
    echo "content" > "$TEST_DIR/subdir/file.txt"

    run fs "$TEST_DIR/subdir"
    assert_success
    assert_output --partial "subdir"
}


@test "sizes: lists file sizes in a directory" {
    mkdir -p "$TEST_DIR/sizes-test"
    echo "small" > "$TEST_DIR/sizes-test/small.txt"
    echo "larger content here" > "$TEST_DIR/sizes-test/large.txt"

    run sizes "$TEST_DIR/sizes-test"
    assert_success
    assert_output --partial "small.txt"
    assert_output --partial "large.txt"
}


