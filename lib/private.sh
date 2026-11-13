# shellcheck shell=bash
# Private overlay helpers. Safe to source when private/ is absent.
# No set -e, no output, no side effects beyond defining helpers.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
: "${DOTFILES_PRIVATE:=${DOTFILES}/private}"

_private_path() {
    printf '%s\n' "${DOTFILES_PRIVATE}/${1}"
}

_private_has() {
    [ -e "${DOTFILES_PRIVATE}/${1}" ]
}
