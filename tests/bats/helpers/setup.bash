# Shared BATS helpers: load bats-support, bats-assert and bats-file from submodules.
# Resolve the repo root from BATS_TEST_FILENAME so this works at any test depth.

_bats_helpers_root() {
    local start="${BATS_TEST_FILENAME:-$BATS_TEST_DIRNAME}"
    local dir
    dir="$(cd "$(dirname "$start")" && pwd)"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/tests/bats/lib/bats-support" ]; then
            printf '%s\n' "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

_DOTFILES_TEST_ROOT="$(_bats_helpers_root)" || {
    echo "setup.bash: could not find tests/bats/lib from $BATS_TEST_FILENAME" >&2
    return 1
}

# Repository root (same value as DOTFILES for migrated helper tests).
export PROJECT_ROOT="$_DOTFILES_TEST_ROOT"
export DOTFILES="$PROJECT_ROOT"

load "$_DOTFILES_TEST_ROOT/tests/bats/lib/bats-support/load"
load "$_DOTFILES_TEST_ROOT/tests/bats/lib/bats-assert/load"
load "$_DOTFILES_TEST_ROOT/tests/bats/lib/bats-file/load"

# Override bats-file temp helpers: only remove directories we created under TMPDIR.
# Create a private temporary directory named dotfiles-test-*.
temp_make() {
    mktemp -d -t dotfiles-test-XXXXXX
}

# Remove a directory only when it matches the temp_make name pattern under TMPDIR.
temp_del() {
    local dir="$1"
    local base="${TMPDIR:-/tmp}"
    base="${base%/}"
    if [[ -d "$dir" && "$dir" == "$base"/dotfiles-test-* ]]; then
        rm -rf "$dir"
    fi
}

# Load mock helpers when present.
if [ -f "$PROJECT_ROOT/tests/bats/helpers/mocks.bash" ]; then
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/tests/bats/helpers/mocks.bash"
fi
