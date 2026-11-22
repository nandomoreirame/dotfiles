#!/usr/bin/env bash
# Pin default applications for selected MIME types via xdg-mime.
set -eo pipefail

if ! command -v xdg-mime >/dev/null 2>&1; then
  printf '%s\n' "xdg-mime not found; skipping file associations (install xdg-utils)"
  exit 0
fi

_desktop_exists() {
  local desktop="$1" dir
  for dir in "$HOME/.local/share/applications" /usr/share/applications /usr/local/share/applications; do
    [ -f "$dir/$desktop" ] && return 0
  done
  return 1
}

# _set_default <handler> <mime...>: set only MIME types with no default.
# REPLACEABLE lists handlers that may be replaced anyway (space-separated).
_set_default() {
  local handler="$1"; shift
  local mime
  if ! _desktop_exists "$handler"; then
    printf '%s\n' "$handler not installed; skipping associations"
    return 0
  fi
  local current
  for mime in "$@"; do
    # Never override a default the user (or another app) already chose.
    current="$(xdg-mime query default "$mime" 2>/dev/null || true)"
    if [ -n "$current" ] && [ "$current" != "$handler" ] && [[ " ${REPLACEABLE:-} " == *" $current "* ]]; then
      printf '  %s: replacing %s\n' "$mime" "$current"
    elif [ -n "$current" ]; then
      printf '  %s already opens with %s (kept)\n' "$mime" "$current"
      continue
    fi
    xdg-mime default "$handler" "$mime" \
      && printf '  %s -> %s\n' "$mime" "$handler" \
      || printf '  failed to associate %s (continuing)\n' "$mime"
  done
}

printf '%s\n' "Applying default file associations..."

# Luciole is the file manager; it takes over folders from Nautilus, a GNOME default.
REPLACEABLE="org.gnome.Nautilus.desktop" _set_default dev.noctalia.luciole.desktop inode/directory

_set_default libreoffice-calc.desktop \
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet \
  application/vnd.ms-excel \
  application/vnd.ms-excel.sheet.macroenabled.12 \
  text/csv

printf '%s\n' "File associations applied"
