#!/usr/bin/env bash
# Resolve the clone root under bash or when sourced from zsh with DOTFILES set.
if [ -z "${DOTFILES:-}" ]; then
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  else
    DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
  fi
fi
# shellcheck source=lib/output.sh
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  # shellcheck disable=SC1091
  source "${BASH_SOURCE[0]%/*}/output.sh"
else
  # shellcheck disable=SC1091
  source "${DOTFILES}/lib/output.sh"
fi

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

