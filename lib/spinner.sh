#!/usr/bin/env bash
# Shared loading spinner for installers, setup steps and the zsh wrappers
# (push, pull, commit). Works when bash or zsh sources it.
#
#   spin_run <message> <command...>
#
# Runs the command in the background with its output in a temporary log and
# keeps its exit code.
#   - With a terminal on stderr: a braille spinner, then a check line on success
#     (output hidden unless SPIN_SHOW_OUTPUT=1) or a cross line plus the output
#     on failure.
#   - Without a terminal (tests, CI, pipes): the message once, then the output.
#
# Environment:
#   DOTFILES_SPINNER=1|0  force the spinner on or off (default: auto, stderr is a tty)
#   SPIN_IDLE=<seconds>   kill the command after that long without new output; returns 124
#   SPIN_LOG=<file>       also copy the command output to <file>
#   SPIN_SHOW_OUTPUT=1    print the output after a successful spinner run

_spin_enabled() {
    case "${DOTFILES_SPINNER:-}" in
    1) return 0 ;;
    0) return 1 ;;
    esac
    [ -t 2 ]
}

spin_run() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        setopt localoptions ksharrays nomonitor
    fi
    local msg="$1"
    shift
    local idle="${SPIN_IDLE:-0}" out pid ret=0 timed_out=0 animate=0
    local i=0 last_size=0 quiet_since=$SECONDS quiet_tick=-1 now size
    # Braille dots as UTF-8 byte escapes: the file stays ASCII in any locale.
    local frames=($'\xe2\xa0\x8b' $'\xe2\xa0\x99' $'\xe2\xa0\xb9' $'\xe2\xa0\xb8' $'\xe2\xa0\xbc'
        $'\xe2\xa0\xb4' $'\xe2\xa0\xa6' $'\xe2\xa0\xa7' $'\xe2\xa0\x87' $'\xe2\xa0\x8f')
    local check=$'\xe2\x9c\x94' cross=$'\xe2\x9c\x96'

    case "$idle" in '' | *[!0-9]*) idle=0 ;; esac
    if _spin_enabled; then
        animate=1
    fi
    out="$(mktemp -t spin.XXXXXX)" || return 1
    [ "$animate" = 1 ] || printf '%s\n' "$msg" >&2

    "$@" >"$out" 2>&1 &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        if [ "$idle" -gt 0 ]; then
            now=$SECONDS
            if [ "$now" -ne "$quiet_tick" ]; then
                quiet_tick=$now
                size=$(stat -c %s "$out" 2>/dev/null || echo 0)
                if [ "$size" -ne "$last_size" ]; then
                    last_size=$size
                    quiet_since=$now
                elif [ $((now - quiet_since)) -ge "$idle" ]; then
                    kill -TERM "$pid" 2>/dev/null
                    pkill -TERM -P "$pid" 2>/dev/null
                    sleep 0.2
                    kill -KILL "$pid" 2>/dev/null
                    pkill -KILL -P "$pid" 2>/dev/null
                    timed_out=1
                    break
                fi
            fi
        fi
        if [ "$animate" = 1 ]; then
            printf '\r\033[2K\033[33m%s\033[0m %s' "${frames[$((i % 10))]}" "$msg" >&2
        fi
        sleep 0.08
        i=$((i + 1))
    done
    wait "$pid" 2>/dev/null || ret=$?
    if [ "$timed_out" = 1 ]; then
        ret=124
    fi

    if [ "$animate" = 1 ]; then
        printf '\r\033[2K' >&2
        if [ "$ret" -eq 0 ]; then
            printf '\033[32m%s\033[0m %s\n' "$check" "$msg" >&2
            if [ "${SPIN_SHOW_OUTPUT:-0}" = 1 ]; then
                cat "$out"
            fi
        else
            printf '\033[31m%s\033[0m %s (exit %s)\n' "$cross" "$msg" "$ret" >&2
            cat "$out" >&2
        fi
    else
        cat "$out"
    fi
    if [ -n "${SPIN_LOG:-}" ]; then
        cp "$out" "$SPIN_LOG"
    fi
    rm -f "$out"
    return "$ret"
}

# Ask for the sudo password before a spinner starts, so the prompt is never
# hidden behind the animation. No-op without a terminal or in dry-run mode.
spin_sudo_prime() {
    [ "${DOTFILES_DRY_RUN:-0}" = 1 ] && return 0
    _spin_enabled || return 0
    command -v sudo >/dev/null 2>&1 || return 0
    sudo -n true 2>/dev/null && return 0
    sudo -v
}
