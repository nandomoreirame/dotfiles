#!/usr/bin/env bash
# Apply a dark appearance for GTK/libadwaita apps via gsettings.
set -eo pipefail

if ! command -v gsettings >/dev/null 2>&1; then
  printf '%s\n' "gsettings not found; skipping GTK dark appearance (install dconf)"
  exit 0
fi

gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"

for schema in org.gtk.Settings.FileChooser org.gtk.gtk4.Settings.FileChooser; do
  if gsettings list-schemas 2>/dev/null | grep -qx "$schema"; then
    gsettings set "$schema" startup-mode "cwd"
  fi
done

printf '%s\n' "GTK dark appearance applied (color-scheme=prefer-dark)"
