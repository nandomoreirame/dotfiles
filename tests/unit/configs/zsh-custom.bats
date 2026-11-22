#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    CUSTOM="$ROOT/.oh-my-zsh/custom"
}

# stdin is /dev/null: a stub that reads stdin (cat) must never wait on the runner.
zrun() { run zsh -f -c "export DOTFILES='$ROOT'; source '$CUSTOM/aliases.zsh'; source '$CUSTOM/functions.zsh'; $1" </dev/null; }

@test "no rm cp or mv alias is defined" {
    zrun 'alias rm cp mv 2>&1; true'
    [[ "$output" != *"rm -rf"* ]]
    [[ "$output" != *"cp -rv"* ]]
    run grep -nE '^alias (rm|cp|mv)=' "$CUSTOM/aliases.zsh"
    [ "$status" -ne 0 ]
}

@test "no ai wrapper or insecure browser function is defined" {
    for fn in claude codex commit chrome-insecure; do
        run grep -rnE "^${fn}\(\)" "$CUSTOM/functions.zsh" "$CUSTOM/functions"
        [ "$status" -ne 0 ]
    done
    [ ! -e "$CUSTOM/functions/ai-clis.zsh" ]
    [ ! -e "$CUSTOM/functions/browser.zsh" ]
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
    _a="nando""moreira"
    run grep -rn '${_a}' "$CUSTOM/functions.zsh" "$CUSTOM/functions"
    [ "$status" -ne 0 ]
}

@test "custom files are in english" {
    run grep -nE "[áàâãéêíóôõúç]|\b(não|erro|arquivo|concluiu)\b" "$CUSTOM"/*.zsh "$CUSTOM"/functions/*.zsh
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

@test "http-server alias binds to localhost only" {
    run grep -nE '^alias http-server=' "$CUSTOM/aliases.zsh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"127.0.0.1"* ]]
    [[ "$output" != *"0.0.0.0"* ]]
    [[ "$output" != *"cors-allow-origin='*'"* ]]
}

@test "functions.zsh sources the generic modules in order" {
    run grep -E '^for _zsh_fn_mod in ' "$CUSTOM/functions.zsh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"spinner git navigation http download gcp"* ]]
    for m in spinner git navigation http download gcp; do
        [ -f "$CUSTOM/functions/$m.zsh" ]
    done
}

@test "_run_with_spinner idle timeout returns 124" {
    zrun '_SPINNER_IDLE=1 _run_with_spinner "x" sleep 30'
    [ "$status" -eq 124 ]
}

@test "_run_with_spinner copies the output to _SPINNER_LOG" {
    zrun 'log=$(mktemp); _SPINNER_LOG="$log" _run_with_spinner "x" echo hello >/dev/null 2>&1; cat "$log"'
    [[ "$output" == *"hello"* ]]
}

@test "push and pull run git through the spinner and keep its exit code" {
    fake="$BATS_TEST_TMPDIR/fake"; mkdir -p "$fake"
    printf '#!/bin/sh\necho "git $*"\n[ "$1" = pull ] && exit 3\nexit 0\n' > "$fake/git"
    chmod +x "$fake/git"
    zrun "export PATH='$fake':\$PATH; push origin main"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git push origin main"* ]]
    zrun "export PATH='$fake':\$PATH; pull --rebase"
    [ "$status" -eq 3 ]
    [[ "$output" == *"git pull --rebase"* ]]
}

# ---- dotenv_load: .env files exported as environment, parsed (never executed) ----

@test "dotenv_load exports KEY=value lines with optional export and quotes" {
    f="$BATS_TEST_TMPDIR/a.env"
    printf '# comment\n\nPLAIN=one\nexport EXPORTED=two\nDQ="three four"\nSQ='"'"'five'"'"'\n' > "$f"
    zrun "dotenv_load '$f'; print -r -- \"\$PLAIN|\$EXPORTED|\$DQ|\$SQ\"; env | grep -c '^PLAIN=one$'"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "one|two|three four|five" ]
    [ "${lines[1]}" = "1" ]
}

@test "dotenv_load never executes command substitution" {
    f="$BATS_TEST_TMPDIR/b.env"
    printf 'EVIL=$(touch %s/pwned)\nTICK=`touch %s/pwned2`\n' "$BATS_TEST_TMPDIR" "$BATS_TEST_TMPDIR" > "$f"
    zrun "dotenv_load '$f'; print -r -- \"\$EVIL\""
    [ ! -e "$BATS_TEST_TMPDIR/pwned" ]
    [ ! -e "$BATS_TEST_TMPDIR/pwned2" ]
    [[ "$output" == *'$(touch'* ]]
}

@test "dotenv_load skips invalid lines and a missing file quietly" {
    f="$BATS_TEST_TMPDIR/c.env"
    printf 'not a pair\n1BAD=x\nGOOD=y\n' > "$f"
    zrun "dotenv_load '$f'; dotenv_load '$BATS_TEST_TMPDIR/none.env'; print -r -- \"\$GOOD\""
    [ "$status" -eq 0 ]
    [ "$output" = "y" ]
}

@test "dotenv_load_dotfiles loads the repo .env, then the overlay .env, which wins" {
    d="$BATS_TEST_TMPDIR/dot"; mkdir -p "$d/private"
    printf 'A=repo\nB=repo\n' > "$d/.env"
    printf 'B=overlay\n' > "$d/private/.env"
    zrun "dotenv_load_dotfiles '$d' '$d/private'; print -r -- \"\$A \$B\""
    [ "$status" -eq 0 ]
    [ "$output" = "repo overlay" ]
}

@test ".zshrc calls dotenv_load_dotfiles without naming the .env paths" {
    grep -q 'dotenv_load_dotfiles' "$ROOT/configs/.zshrc"
}
