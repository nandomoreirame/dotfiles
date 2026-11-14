#!/usr/bin/env bats

# Git profile module tests (filled in task 2).

load '../../bats/helpers/setup'

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export DOTFILES="$ROOT"
}

@test "_profile_list_git_configs: lists git*.conf files" {
    skip "migrated in task 2"
}

@test "_profile_list_git_configs: returns empty for a profile without configs" {
    skip "migrated in task 2"
}
