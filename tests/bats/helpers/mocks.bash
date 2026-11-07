#!/usr/bin/env bash
# Mock helpers for BATS tests: stub external commands on PATH.

MOCK_DIR=""

# Create a private mock directory and put it first on PATH.
mock_init() {
    MOCK_DIR=$(mktemp -d -t dotfiles-mock-XXXXXX)
    export PATH="$MOCK_DIR:$PATH"
}

# Remove the mock directory when it matches the expected name pattern.
mock_cleanup() {
    local base="${TMPDIR:-/tmp}"
    base="${base%/}"
    if [[ -d "$MOCK_DIR" && "$MOCK_DIR" == "$base"/dotfiles-mock-* ]]; then
        rm -rf "$MOCK_DIR"
    fi
    MOCK_DIR=""
}

# Install a stub named $1 that runs the shell code in $2.
mock_command() {
    local cmd="$1"
    local code="$2"

    if [ -z "$MOCK_DIR" ]; then
        mock_init
    fi

    cat >"$MOCK_DIR/$cmd" <<EOF
#!/usr/bin/env bash
$code
EOF
    chmod +x "$MOCK_DIR/$cmd"
}
