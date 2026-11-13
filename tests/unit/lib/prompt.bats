#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

p() { env -i HOME="$HOME" PATH="/usr/bin:/bin" "$@" bash -c "source '$ROOT/lib/prompt.sh'; $PCMD"; }

@test "_confirm auto-confirms with DOTFILES_YES=1" {
    PCMD='_confirm "Proceed?"'
    run p DOTFILES_YES=1
    [ "$status" -eq 0 ]
}

@test "_confirm fails without hanging when stdin is not a terminal" {
    PCMD='_confirm "Proceed?"'
    run timeout 5 env -i HOME="$HOME" PATH="/usr/bin:/bin" bash -c "source '$ROOT/lib/prompt.sh'; _confirm 'Proceed?' </dev/null"
    [ "$status" -eq 1 ]
}

@test "_confirm reads y from stdin when asked to" {
    run bash -c "printf 'y\n' | env -i HOME=\"\$HOME\" PATH=/usr/bin:/bin DOTFILES_PROMPT_STDIN=1 bash -c \"source '$ROOT/lib/prompt.sh'; _confirm 'Proceed?'\""
    [ "$status" -eq 0 ]
}

@test "_confirm reads n and honors the default on empty input" {
    run bash -c "printf 'n\n' | env -i HOME=\"\$HOME\" PATH=/usr/bin:/bin DOTFILES_PROMPT_STDIN=1 bash -c \"source '$ROOT/lib/prompt.sh'; _confirm 'Proceed?'\""
    [ "$status" -eq 1 ]
    run bash -c "printf '\n' | env -i HOME=\"\$HOME\" PATH=/usr/bin:/bin DOTFILES_PROMPT_STDIN=1 bash -c \"source '$ROOT/lib/prompt.sh'; _confirm 'Proceed?' yes\""
    [ "$status" -eq 0 ]
}

@test "_choose prints the selected item" {
    run bash -c "printf '2\n' | env -i HOME=\"\$HOME\" PATH=/usr/bin:/bin DOTFILES_PROMPT_STDIN=1 bash -c \"source '$ROOT/lib/prompt.sh'; _choose 'Pick one' alpha beta gamma\""
    [ "$status" -eq 0 ]
    [[ "$output" == *"beta"* ]]
}

@test "_choose rejects an out of range answer" {
    run bash -c "printf '9\n' | env -i HOME=\"\$HOME\" PATH=/usr/bin:/bin DOTFILES_PROMPT_STDIN=1 bash -c \"source '$ROOT/lib/prompt.sh'; _choose 'Pick one' alpha beta\""
    [ "$status" -ne 0 ]
}

@test "_choose takes the first item with DOTFILES_YES=1" {
    PCMD="_choose 'Pick one' alpha beta"
    run p DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"alpha"* ]]
}
