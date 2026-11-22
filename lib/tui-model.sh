#!/usr/bin/env bash
# Screen-free logic behind `dotfiles tui` (bin/utils/dotfiles-tui).
#
# The install checklist stays locked until the prerequisites gate passes: the
# base tools exist and the system has no pending updates. Every checklist step
# is one `dotfiles` command, so the TUI never duplicates install logic.
# Safe under `set -euf` (tuish's compat.sh turns it on): no globs, no unset
# variables.

# Command used to run the steps; tests point it at a stub.
: "${DOTFILES_TUI_CLI:=dotfiles}"

# Base tools checked by `command -v`, then pacman packages checked by `-Q`.
readonly _TUI_BASE_COMMANDS="git curl sudo"
readonly _TUI_BASE_PACKAGES="base-devel"

# _tui_base_missing: print each missing base item, one per line.
# "aur-helper" stands for "neither yay nor paru".
_tui_base_missing() {
    local item
    for item in $_TUI_BASE_COMMANDS; do
        command -v "$item" >/dev/null 2>&1 || printf '%s\n' "$item"
    done
    for item in $_TUI_BASE_PACKAGES; do
        pacman -Q "$item" >/dev/null 2>&1 || printf '%s\n' "$item"
    done
    if ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
        printf '%s\n' aur-helper
    fi
}

# _tui_base_packages <item...>: the pacman packages that install the items.
# The AUR helper is built by the install flow, not by pacman.
_tui_base_packages() {
    local item out=""
    for item in "$@"; do
        [ "$item" = aur-helper ] && continue
        out="${out:+$out }$item"
    done
    printf '%s\n' "$out"
}

# _tui_pending_updates: print the number of pending updates. checkupdates
# exits 2 when there are none and 1 when the check itself failed (no network,
# no database); a failed check returns 1 so it is never read as "up to date".
_tui_pending_updates() {
    local out rc=0 line count=0
    out="$(checkupdates 2>/dev/null)" || rc=$?
    case "$rc" in
        0)
            # Count in bash: no grep or wc dependency.
            while IFS= read -r line; do
                [ -n "$line" ] && count=$((count + 1))
            done <<<"$out"
            printf '%s\n' "$count"
            ;;
        2) printf '0\n' ;;
        *) return 1 ;;
    esac
}

# _tui_ready: the gate. True when nothing is missing and no update is pending.
_tui_ready() {
    local pending
    [ -z "$(_tui_base_missing)" ] || return 1
    pending="$(_tui_pending_updates)" || return 1
    [ "$pending" -eq 0 ]
}

# _tui_steps: the install checklist as "id|label" lines, in run order.
_tui_steps() {
    printf '%s\n' \
        'pacman|Arch packages (pacman)' \
        'aur|AUR packages' \
        'flatpak|Flatpak apps' \
        'node|Global npm packages' \
        'sh|Shell apps (oh-my-zsh, mise, docker)' \
        'fonts|Fonts' \
        'langs|Language runtimes (mise)' \
        'links|Configuration links' \
        'setup|Setup scripts'
}

# _tui_step_args <id>: the dotfiles arguments for one step.
_tui_step_args() {
    case "${1:-}" in
        pacman | aur | flatpak | node | sh) printf 'packages install --manager %s --yes\n' "$1" ;;
        fonts) printf 'fonts install --yes\n' ;;
        langs) printf 'langs install\n' ;;
        links) printf 'links create\n' ;;
        setup) printf 'setup --yes\n' ;;
        *) return 1 ;;
    esac
}

# _tui_run_steps <id...>: run the steps in order, keep going after a failure.
# Sets TUI_FAILED_STEPS and returns 1 when any step failed.
_tui_run_steps() {
    local id args
    TUI_FAILED_STEPS=()
    for id in "$@"; do
        args="$(_tui_step_args "$id")" || { TUI_FAILED_STEPS+=("$id"); continue; }
        printf '\n==> %s: %s %s\n' "$id" "$DOTFILES_TUI_CLI" "$args"
        # shellcheck disable=SC2086 # args is a fixed word list from _tui_step_args
        "$DOTFILES_TUI_CLI" $args || TUI_FAILED_STEPS+=("$id")
    done
    [ "${#TUI_FAILED_STEPS[@]}" -eq 0 ]
}
