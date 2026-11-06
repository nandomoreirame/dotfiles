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

load "$_DOTFILES_TEST_ROOT/tests/bats/lib/bats-support/load"
load "$_DOTFILES_TEST_ROOT/tests/bats/lib/bats-assert/load"
load "$_DOTFILES_TEST_ROOT/tests/bats/lib/bats-file/load"
