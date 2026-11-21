#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Mark Habit Done
# @vicinae.description Mark a habit done today in Beaver Habits
# @vicinae.packageName Beaver Habits
# @vicinae.mode compact
# @vicinae.keywords ["habit", "habito", "done", "feito"]
# @vicinae.argument1 { "type": "text", "placeholder": "habit" }
exec "$HOME/.dotfiles/bin/utils/beaverhabits" "done" "$1"
