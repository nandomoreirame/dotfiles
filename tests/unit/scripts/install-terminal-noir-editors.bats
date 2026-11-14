#!/usr/bin/env bats

# Unit tests for scripts/themes/install-terminal-noir-editors
#
# Run:
#   ./tests/run-tests unit/scripts/install-terminal-noir-editors.bats
#
# `code` and `cursor` are stubbed on PATH: each records its arguments and keeps
# a copy of the VSIX it was handed, so the package contents can be checked.

load '../../bats/helpers/setup'

SCRIPT="$PROJECT_ROOT/scripts/themes/install-terminal-noir-editors"

setup() {
    TEST_DIR="$(temp_make)"
    STUB_DIR="$TEST_DIR/stubs"
    CALL_LOG="$TEST_DIR/calls.log"
    mkdir -p "$STUB_DIR"
    : > "$CALL_LOG"

    local editor
    for editor in code cursor; do
        cat > "$STUB_DIR/$editor" <<STUB
#!/usr/bin/env bash
echo "$editor \$*" >> "\$CALL_LOG"
for arg in "\$@"; do
    case "\$arg" in *.vsix) cp "\$arg" "\$TEST_DIR/$editor.vsix" ;; esac
done
STUB
        chmod +x "$STUB_DIR/$editor"
    done

    # Only the tools the script needs, so the real editors in /usr/bin stay
    # out of reach.
    local tool
    for tool in bash jq bsdtar mktemp cp mkdir rm dirname cat; do
        ln -s "/usr/bin/$tool" "$STUB_DIR/$tool"
    done

    export CALL_LOG TEST_DIR
}

# BASH_ENV (~/.bashrc) re-prepends the real PATH in a child bash, which would
# run the real editors; a clean env keeps the stubs first.
run_script() {
    run env -i HOME="$TEST_DIR" CALL_LOG="$CALL_LOG" TEST_DIR="$TEST_DIR" \
        PATH="$STUB_DIR" "$STUB_DIR/bash" "$SCRIPT"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "installs the packaged theme in both editors" {
    run_script

    assert_success
    grep -Eq '^code --install-extension .*terminal-noir-1\.0\.0\.vsix --force$' "$CALL_LOG"
    grep -Eq '^cursor --install-extension .*terminal-noir-1\.0\.0\.vsix --force$' "$CALL_LOG"
}

@test "the VSIX holds the manifest and the generated extension files" {
    run_script
    assert_success

    run unzip -Z1 "$TEST_DIR/code.vsix"
    [[ "$output" == *"[Content_Types].xml"* ]]
    [[ "$output" == *"extension.vsixmanifest"* ]]
    [[ "$output" == *"extension/package.json"* ]]
    [[ "$output" == *"extension/themes/terminal-noir-color-theme.json"* ]]

    run unzip -p "$TEST_DIR/code.vsix" extension.vsixmanifest
    local publisher
    publisher="$(printf '%s' "nando""moreira")"
    [[ "$output" == *"Id=\"terminal-noir\" Version=\"1.0.0\" Publisher=\"${publisher}\""* ]]

    unzip -p "$TEST_DIR/code.vsix" extension/package.json \
        | cmp -s - "$PROJECT_ROOT/configs/vscode/terminal-noir/package.json"
}

@test "skips an editor that is not installed" {
    rm "$STUB_DIR/cursor"

    run_script

    assert_success
    grep -q '^code ' "$CALL_LOG"
    ! grep -q '^cursor ' "$CALL_LOG"
    [[ "$output" == *"cursor"* ]]
}

@test "fails when neither editor is installed" {
    rm "$STUB_DIR/code" "$STUB_DIR/cursor"

    run_script

    assert_failure
}
