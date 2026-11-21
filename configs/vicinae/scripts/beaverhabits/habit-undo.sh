#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Unmark Habit
# @vicinae.description Mark a habit not done today in Beaver Habits
# @vicinae.packageName Beaver Habits
# @vicinae.mode compact
# @vicinae.keywords ["habit", "habito", "undo", "desfazer"]
# @vicinae.argument1 { "type": "text", "placeholder": "habit" }
exec "$HOME/.dotfiles/bin/utils/beaverhabits" undo "$1"
