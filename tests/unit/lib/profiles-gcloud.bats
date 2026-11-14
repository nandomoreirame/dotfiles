#!/usr/bin/env bats

# GCloud profile module tests (filled in task 3).

load '../../bats/helpers/setup'

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export DOTFILES="$ROOT"
}

@test "_profile_list_gcloud_configs: lists gcloud*.conf files" {
    skip "migrated in task 3"
}
