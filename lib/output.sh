#!/usr/bin/env bash

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# BASH_SOURCE is empty when zsh sources this file; fall back to $DOTFILES/lib.
_lib_dir="${BASH_SOURCE[0]%/*}"
[ -n "${BASH_SOURCE[0]:-}" ] || _lib_dir="$DOTFILES/lib"
# shellcheck source=lib/environments.sh
source "$_lib_dir/environments.sh"
unset _lib_dir

#
# Headers and Logging
#

e_header() {
    printf "\n${bold}${purple}==========  %s  ==========${reset}\n" "$@"
}
e_arrow() {
    printf "➜ %s\n" "$@"
}
e_success() {
    printf "${green}✔ %s${reset}\n" "$@"
}
e_info() {
    printf "${blue}ℹ %s${reset}\n" "$@"
}
e_error() {
    printf "${red}✖ %s${reset}\n" "$@"
}
e_warning() {
    printf "${tan}➜ %s${reset}\n" "$@"
}
e_underline() {
    printf "${underline}${bold}%s${reset}\n" "$@"
}
e_bold() {
    printf "${bold}%s${reset}\n" "$@"
}
# _failure_record <label> <items...>: remember a failure for the install summary.
_failure_record() {
    local label="$1"
    shift
    DOTFILES_FAILURES+=("$label: $*")
}

e_note() {
    printf "${underline}${bold}${blue}Note:${reset}  ${blue}%s${reset}\n" "$@"
}
