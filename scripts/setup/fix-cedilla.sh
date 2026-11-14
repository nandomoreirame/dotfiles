#!/usr/bin/env bash
# Configure ~/.XCompose so 'c produces a cedilla instead of an accented c.
# Based on https://github.com/marcopaganini/gnome-cedilla-fix
set -eo pipefail

LANG="${LANG:=en_US.UTF-8}"
COMPOSE_DIR="${DOTFILES_COMPOSE_DIR:-/usr/share/X11/locale}"
USER_COMPOSE="$HOME/.XCompose"

if [ ! -d "$COMPOSE_DIR" ]; then
  printf '%s\n' "Compose locale directory missing; skipping cedilla fix"
  exit 0
fi

system_compose=${COMPOSE_DIR}/$(sed -ne "s/^\([^:]*\):[ \t]*$LANG/\1/p" <"${COMPOSE_DIR}/compose.dir" 2>/dev/null | head -1)
if [ -z "${system_compose}" ] || [ ! -s "${system_compose}" ]; then
  printf '%s\n' "No system Compose file for LANG=${LANG}; skipping"
  exit 0
fi

tmp="$(mktemp)"
# shellcheck disable=SC2064
trap 'rm -f "$tmp"' EXIT
sed -e 's/\xc4\x87/\xc3\xa7/g' -e 's/\xc4\x86/\xc3\x87/g' <"${system_compose}" >"$tmp"

if [ -s "${USER_COMPOSE}" ] && cmp -s "$tmp" "${USER_COMPOSE}"; then
  printf '%s\n' "Cedilla Compose file already configured"
  exit 0
fi

if [ -s "${USER_COMPOSE}" ] && [ ! -e "${USER_COMPOSE}.ORIGINAL" ]; then
  cp -f "${USER_COMPOSE}" "${USER_COMPOSE}.ORIGINAL"
fi
cp -f "$tmp" "${USER_COMPOSE}"
printf '%s\n' "Wrote ${USER_COMPOSE}; log out of the graphical session to apply"
