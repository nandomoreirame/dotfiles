#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    CUSTOM="$ROOT/.oh-my-zsh/custom"
}

zrun() { run zsh -f -c "export DOTFILES='$ROOT'; source '$CUSTOM/aliases.zsh'; source '$CUSTOM/functions.zsh'; $1"; }

@test "no rm cp or mv alias is defined" {
    zrun 'alias rm cp mv 2>&1; true'
    [[ "$output" != *"rm -rf"* ]]
    [[ "$output" != *"cp -rv"* ]]
    run grep -nE '^alias (rm|cp|mv)=' "$CUSTOM/aliases.zsh"
    [ "$status" -ne 0 ]
}

@test "no ai wrapper or insecure browser function is defined" {
    for fn in claude codex commit chrome-insecure; do
        run grep -nE "^${fn}\(\)" "$CUSTOM/functions.zsh"
        [ "$status" -ne 0 ]
    done
    run grep -rnE 'dangerously|--yolo|disable-web-security' "$CUSTOM"
    [ "$status" -ne 0 ]
}

@test "author folder and font aliases are absent" {
    run grep -nE '^alias "?(brain|projects|clients|mi)"?=' "$CUSTOM/aliases.zsh"
    [ "$status" -ne 0 ]
}

@test "gcp-set-project has no built-in project id" {
    zrun 'unset PROJECT_ID; gcp-set-project'
    [ "$status" -ne 0 ]
    [[ "$output" == *"project"* ]]
    run grep -n 'nandomoreira' "$CUSTOM/functions.zsh"
    [ "$status" -ne 0 ]
}

@test "custom files are in english" {
    run grep -nE "[áàâãéêíóôõúç]|\b(não|erro|arquivo|concluiu)\b" "$CUSTOM"/*.zsh
    [ "$status" -ne 0 ]
}
