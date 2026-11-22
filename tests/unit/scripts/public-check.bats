#!/usr/bin/env bats

setup() { ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"; }

# Sensitive samples are assembled at run time so this file never contains one literally.
cpf()   { printf '%s' "123.456.789-""09"; }
cnpj()  { printf '%s' "12.345.678/0001-""95"; }
phone() { printf '%s' "(11) 9""1234-5678"; }
wame()  { printf '%s' "https://wa.me/5511""912345678"; }
ip()    { printf '%s' "192.168.""1.20"; }
tsip()  { printf '%s' "100.64.""0.9"; }
home()  { printf '%s' "/home/""someone/x"; }
mail()  { printf '%s' "me@gma""il.com"; }

mkrepo() {
    R="$BATS_TEST_TMPDIR/r"; rm -rf "$R"; mkdir -p "$R"
    git -C "$R" init -q -b main
    printf '%s\n' "$1" > "$R/f.txt"
    git -C "$R" add f.txt
}
gate() { run bash "$ROOT/scripts/public-check" "$@"; }

@test "public-check rejects a cpf" { mkrepo "doc $(cpf)"; gate "$R"; [ "$status" -ne 0 ]; [[ "$output" == *"f.txt:1:"* ]]; }
@test "public-check rejects a cnpj" { mkrepo "x $(cnpj)"; gate "$R"; [ "$status" -ne 0 ]; }
@test "public-check rejects a phone number" { mkrepo "x $(phone)"; gate "$R"; [ "$status" -ne 0 ]; }
@test "public-check rejects a whatsapp link" { mkrepo "x $(wame)"; gate "$R"; [ "$status" -ne 0 ]; }
@test "public-check rejects private ipv4 ranges" {
    mkrepo "h $(ip)"; gate "$R"; [ "$status" -ne 0 ]
    mkrepo "h $(tsip)"; gate "$R"; [ "$status" -ne 0 ]
}
@test "public-check rejects a home path" { mkrepo "p $(home)"; gate "$R"; [ "$status" -ne 0 ]; }
@test "public-check rejects a personal e-mail" { mkrepo "$(mail)"; gate "$R"; [ "$status" -ne 0 ]; }

@test "public-check allows documentation values" {
    # Build the fixture at run time so the source file never holds a joined e-mail list
    # that the gate would mis-read around literal "\n" sequences.
    mkrepo "$(printf '%s\n' 'a@example.com' 'b@users.noreply.github.com' 'git@github.com:o/r.git' '198.51.100.7' '192.0.2.1')"
    gate "$R"; [ "$status" -eq 0 ]
}

@test "public-check honors the allow file" {
    local demo
    demo="$(printf '%s' "owner@acme-""demo.org")"
    mkrepo "$demo"
    printf 'email:%s\n' "$demo" > "$R/scripts-allow"
    mkdir -p "$R/scripts"; mv "$R/scripts-allow" "$R/scripts/public-check.allow"; git -C "$R" add -A
    gate "$R"; [ "$status" -eq 0 ]
}

@test "public-check rejects forbidden paths" {
    mkrepo ok
    mkdir -p "$R/private" "$R/docs/plans"; echo x > "$R/private/a"; echo x > "$R/.env.prod"; echo x > "$R/docs/plans/p.md"
    git -C "$R" add -f private/a .env.prod docs/plans/p.md
    gate "$R"; [ "$status" -ne 0 ]
    [[ "$output" == *"private/a"* ]]
    [[ "$output" == *".env.prod"* ]]
    [[ "$output" == *"docs/plans/p.md"* ]]
}

@test "public-check allows only the two overlay docs under private" {
    mkrepo ok
    mkdir -p "$R/private"; echo x > "$R/private/README.md"; echo x > "$R/private/private-overlay.md"
    git -C "$R" add -f private/README.md private/private-overlay.md
    gate "$R"; [ "$status" -eq 0 ]
    echo x > "$R/private/secret.txt"; git -C "$R" add -f private/secret.txt
    gate "$R"; [ "$status" -ne 0 ]
    [[ "$output" == *"private/secret.txt"* ]]
}

@test "public-check rejects any tracked docs path" {
    mkrepo ok
    mkdir -p "$R/docs"; echo x > "$R/docs/guide.md"
    git -C "$R" add -f docs/guide.md
    gate "$R"; [ "$status" -ne 0 ]
    [[ "$output" == *"docs/guide.md"* ]]
}

@test "public-check ignores untracked files" {
    mkrepo ok
    printf 'p %s\n' "$(home)" > "$R/untracked.txt"
    gate "$R"; [ "$status" -eq 0 ]
}

@test "public-check --staged reads only staged files" {
    mkrepo ok
    git -C "$R" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm base
    printf 'p %s\n' "$(home)" > "$R/new.txt"
    gate --staged "$R"; [ "$status" -eq 0 ]
    git -C "$R" add new.txt
    gate --staged "$R"; [ "$status" -ne 0 ]
}

@test "public-check skips binary files" {
    mkrepo ok
    { printf '\000\001'; printf '%s' "$(cpf)"; } > "$R/bin.dat"; git -C "$R" add bin.dat
    gate "$R"; [ "$status" -eq 0 ]
}

@test "public-check runs gitleaks when installed" {
    mkrepo ok
    FAKE="$BATS_TEST_TMPDIR/fake"; mkdir -p "$FAKE"
    printf '#!/bin/sh\necho leak-found\nexit 1\n' > "$FAKE/gitleaks"; chmod +x "$FAKE/gitleaks"
    run env -i HOME="$HOME" PATH="$FAKE:/usr/bin:/bin" bash "$ROOT/scripts/public-check" "$R"
    [ "$status" -ne 0 ]
    [[ "$output" == *"leak-found"* ]]
}

@test "public-check rejects a non-allowlisted author credit" {
    local handle
    handle="$(printf '%s' "nando""moreira")"
    mkrepo "powered by ${handle}"
    mkdir -p "$R/scripts"; : > "$R/scripts/public-check.allow"; git -C "$R" add -A
    gate "$R"; [ "$status" -ne 0 ]
    [[ "$output" == *"author credit"* ]]
}

@test "public-check allows an exact credit line" {
    local line handle
    handle="$(printf '%s' "nando""moreira")"
    line="from ${handle}.dev."
    mkrepo "$line"
    mkdir -p "$R/scripts"
    printf 'credit:f.txt:%s\n' "$line" > "$R/scripts/public-check.allow"
    git -C "$R" add -A
    gate "$R"; [ "$status" -eq 0 ]
}

@test "public-check ignores the github user that contains the author handle" {
    local handle
    handle="$(printf '%s' "nando""moreira")"
    mkrepo "git clone git@github.com:${handle}me/dotfiles.git"
    mkdir -p "$R/scripts"; : > "$R/scripts/public-check.allow"; git -C "$R" add -A
    gate "$R"; [ "$status" -eq 0 ]
}

@test "public-check scans large files without one grep per line" {
    mkrepo "clean"
    seq 1 3000 | sed 's/^/plain text line /' > "$R/big.txt"
    git -C "$R" add big.txt
    run timeout 10 bash "$ROOT/scripts/public-check" "$R"
    [ "$status" -eq 0 ]
    [[ "$output" == *"public-check: ok"* ]]
}

@test "public-check reports the line number of each finding" {
    mkrepo "clean"
    printf 'a\nb\n%s\n' "$(ip)" > "$R/f.txt"
    git -C "$R" add f.txt
    gate "$R"; [ "$status" -ne 0 ]
    [[ "$output" == *"f.txt:3: private ipv4"* ]]
}
