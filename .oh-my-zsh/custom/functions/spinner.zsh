# _run_with_spinner <message> <command...>: the shared spinner from
# lib/spinner.sh (also used by the installers), with the output shown after a
# successful run. _SPINNER_IDLE and _SPINNER_LOG map to SPIN_IDLE and SPIN_LOG.
source "$DOTFILES/lib/spinner.sh"

_run_with_spinner() {
  local msg="$1"
  shift
  SPIN_IDLE="${_SPINNER_IDLE:-0}" SPIN_LOG="${_SPINNER_LOG:-}" SPIN_SHOW_OUTPUT=1 \
    spin_run "$msg" "$@"
}
