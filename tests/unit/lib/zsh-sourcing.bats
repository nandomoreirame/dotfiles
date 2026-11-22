#!/usr/bin/env bats

# .zshrc sources lib/functions.sh and lib/profiles.sh in zsh, where BASH_SOURCE
# is empty; the modules they pull in must still find their siblings.

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    command -v zsh >/dev/null || skip "zsh not installed"
}

zsrc() { run zsh -f -c "export DOTFILES='$ROOT'; source '$ROOT/lib/$1' 2>&1; $2"; }

@test "lib/output.sh loads in zsh and defines e_info" {
    zsrc output.sh 'whence -w e_info'
    [ "$status" -eq 0 ]
    [[ "$output" != *"no such file"* ]]
    [[ "$output" == *"e_info: function"* ]]
}

@test "lib/validation.sh loads in zsh without missing siblings" {
    zsrc validation.sh 'true'
    [ "$status" -eq 0 ]
    [[ "$output" != *"no such file"* ]]
}

@test "lib/profiles.sh loads in zsh without errors" {
    zsrc profiles.sh 'whence -w profile_load'
    [ "$status" -eq 0 ]
    [[ "$output" != *"no such file"* && "$output" != *"bad substitution"* ]]
}
