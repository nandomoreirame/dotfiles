#!/usr/bin/env bats

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home" DOTFILES="$ROOT"
    STUBS="$BATS_TEST_TMPDIR/stubs"
    LOG="$BATS_TEST_TMPDIR/calls"
    mkdir -p "$STUBS" "$HOME"
    printf '#!/bin/sh\necho "npm $*" >> "%s"\nif [ "$1" = "list" ]; then\n  case "$*" in *installed-pkg*) echo "└── installed-pkg@1.0.0"; exit 0;; esac\n  exit 1\nfi\nexit 0\n' "$LOG" > "$STUBS/npm"
    chmod +x "$STUBS/npm"
    export DOTFILES_PRIVATE="$BATS_TEST_TMPDIR/private"
    mkdir -p "$DOTFILES_PRIVATE"
    : > "$LOG"
}

run_node() {
    run env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" DOTFILES="$DOTFILES" DOTFILES_PRIVATE="$DOTFILES_PRIVATE" TERM=xterm-256color "$@" bash -c "source '$ROOT/lib/node-packages.sh'; $PCMD"
}

@test "node install skips installed packages" {
    PCMD='_node_packages "installed-pkg new-pkg"'
    run_node DOTFILES_YES=1
    [ "$status" -eq 0 ]
    grep -q "npm install -g -- new-pkg" "$LOG"
    ! grep -q "npm install -g -- installed-pkg" "$LOG"
}

@test "node dry-run prints the commands and installs nothing" {
    PCMD='_node_packages "new-pkg"'
    run_node DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"[dry-run]"* ]]
    ! grep -q "^npm install" "$LOG"
}

@test "node reports a failing package and continues" {
    printf '#!/bin/sh\necho "npm $*" >> "%s"\n[ "$1" = "list" ] && exit 1\ncase "$*" in *bad-pkg*) exit 1;; esac\nexit 0\n' "$LOG" > "$STUBS/npm"
    PCMD='_node_packages "bad-pkg good-pkg"'
    run_node DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"bad-pkg"* ]]
    grep -q "good-pkg" "$LOG"
}

@test "node empty argument uses the public list" {
    PCMD='_node_packages ""'
    run_node DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -eq 0 ]
    [[ "$output" == *"prettier"* ]]
    [[ "$output" == *"eslint"* ]]
}

@test "node fails when npm is missing" {
    rm -f "$STUBS/npm"
    PCMD='_node_packages "new-pkg"'
    run_node DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"npm not found"* ]]
}

@test "node remove asks for confirmation" {
    PCMD='_node_remove "new-pkg" </dev/null'
    run_node
    [ "$status" -ne 0 ]
    ! grep -q "npm uninstall" "$LOG"
}

@test "hostile node package name is rejected" {
    PCMD='_node_packages "--overwrite=*"'
    run_node DOTFILES_DRY_RUN=1 DOTFILES_YES=1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid package name"* ]]
    ! grep -q "npm install" "$LOG"
}

@test "node install passes -- before the package name" {
    PCMD='_node_packages "new-pkg"'
    run_node DOTFILES_YES=1
    [ "$status" -eq 0 ]
    grep -q "npm install -g -- new-pkg" "$LOG"
}
