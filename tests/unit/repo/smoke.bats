#!/usr/bin/env bats
load '../../bats/helpers/setup'

@test "bats helpers load" {
    assert_equal "a" "a"
}
