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

@test "_run_with_spinner propagates the command exit code" {
    zrun '_run_with_spinner "x" sh -c "exit 5"'
    [ "$status" -eq 5 ]
}

@test "http helpers delegate to _http_request" {
    zrun '_http_request() { echo "REQ $*"; }
          http.get https://x.test; http.post https://x.test "{}"; http.put https://x.test "{}"; http.delete https://x.test'
    [[ "$output" == *"REQ GET https://x.test"* ]]
    [[ "$output" == *"REQ POST https://x.test {}"* ]]
    [[ "$output" == *"REQ PUT https://x.test {}"* ]]
    [[ "$output" == *"REQ DELETE https://x.test"* ]]
}

@test "http.get without a URL prints usage and fails" {
    zrun 'http.get'
    [ "$status" -eq 1 ]
    [[ "$output" == *"URL is required"* ]]
}

@test "gcp-set-project runs each gcloud step once" {
    zrun 'gcloud() { echo "gcloud $*" >> "$TMPLOG"; cat >/dev/null; }
          export TMPLOG=$(mktemp); gcp-set-project demo >/dev/null 2>&1
          grep -c "application-default login" "$TMPLOG"; grep -c "config set project demo" "$TMPLOG"'
    [ "${lines[-2]}" = "1" ]
    [ "${lines[-1]}" = "1" ]
}

@test "kept generic aliases still exist" {
    run zsh -f -c "export DOTFILES='$ROOT'; source '$CUSTOM/aliases.zsh'; alias home chrome finder ips py timer zload c dc gs"
    [ "$status" -eq 0 ]
}
