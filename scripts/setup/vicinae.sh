#!/usr/bin/env bash
# Vicinae launcher: make the GUI-owned settings.json import the versioned
# configs/vicinae/dotfiles.json (linked to ~/.config/vicinae/dotfiles.json) and
# enable the launcher's user service.
set -eo pipefail

if ! command -v vicinae >/dev/null 2>&1; then
  printf '%s\n' "vicinae not found; skipping launcher setup (install vicinae-bin)"
  exit 0
fi

settings="${XDG_CONFIG_HOME:-$HOME/.config}/vicinae/settings.json"

if [[ ! -e "$settings" ]]; then
  mkdir -p "${settings%/*}"
  # shellcheck disable=SC2016  # "$schema" is a literal JSON key
  printf '%s\n' '{' \
    '  "$schema": "https://vicinae.com/schemas/config.json",' \
    '  "imports": ["dotfiles.json"]' \
    '}' >"$settings"
  printf '%s\n' "Created $settings importing dotfiles.json"
elif grep -q '"dotfiles\.json"' "$settings"; then
  printf '%s\n' "Vicinae settings already import dotfiles.json"
else
  # The GUI rewrites settings.json (JSON with comments); never edit it here.
  printf '%s\n' "Add \"imports\": [\"dotfiles.json\"] to $settings to load the versioned config"
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user enable --now vicinae.service ||
    printf '%s\n' "Could not enable vicinae.service; start it with: vicinae server"
fi
