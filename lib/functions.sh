#!/usr/bin/env bash
: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/output.sh
source "${BASH_SOURCE[0]%/*}/output.sh"

function mkd() {
    mkdir -p "$@" && cd "$@" || return 1
}

function fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi

    if [[ $# -gt 0 ]]; then
        du "$arg" -- "$@"
    else
        du "$arg" .[^.]* ./* 2>/dev/null
    fi
}

function sizes() {
    du -sxh "${1:-.}"/* 2>/dev/null | sort -rh
}

