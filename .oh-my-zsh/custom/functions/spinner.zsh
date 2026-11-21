# Run <cmd...> in the background with a spinner on stderr. Capture wait status
# before any other command so the exit code is preserved.
#
#   _SPINNER_IDLE=<s>  kill the command after <s> seconds without new output
#                      and return 124 (0 or unset: no limit)
#   _SPINNER_LOG=<f>   also copy the command output to <f>
_run_with_spinner() {
  local msg="$1"
  shift
  local out pid ret timed_out=0
  local idle="${_SPINNER_IDLE:-0}"
  # Braille dots as UTF-8 byte escapes: the file stays ASCII and works in any locale.
  local spin=($'\xe2\xa0\x8b' $'\xe2\xa0\x99' $'\xe2\xa0\xb9' $'\xe2\xa0\xb8' $'\xe2\xa0\xbc' $'\xe2\xa0\xb4' $'\xe2\xa0\xa6' $'\xe2\xa0\xa7' $'\xe2\xa0\x87' $'\xe2\xa0\x8f')
  local i=0 n=${#spin[@]} idx
  local last_size=0 quiet_since=$SECONDS quiet_tick=-1 now size

  [[ "$idle" == <-> ]] || idle=0
  out=$(mktemp -t spinner.XXXXXX) || return 1
  setopt local_options no_monitor
  "$@" >"$out" 2>&1 &
  pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    if (( idle > 0 )); then
      now=$SECONDS
      if (( now != quiet_tick )); then
        quiet_tick=$now
        size=$(stat -c %s "$out" 2>/dev/null || echo 0)
        if (( size != last_size )); then
          last_size=$size
          quiet_since=$now
        elif (( now - quiet_since >= idle )); then
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
    idx=$((i % n + 1))
    printf >&2 '\r\033[2K\033[33m%s\033[0m %s' "${spin[idx]}" "$msg"
    sleep 0.08
    ((i++))
  done
  printf >&2 '\r\033[2K'
  wait "$pid"
  ret=$?
  (( timed_out )) && ret=124
  printf >&2 '\n'
  [[ -n "${_SPINNER_LOG:-}" ]] && cp "$out" "$_SPINNER_LOG"
  cat "$out"
  rm -f "$out"
  return ret
}