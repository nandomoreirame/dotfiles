# dotenv_load <file>: export the KEY=value lines of a .env file.
# The file is parsed, never sourced: no command substitution or expansion runs,
# so a hostile .env cannot execute code. Accepts `export KEY=value`, single or
# double quotes, comments and blank lines; skips anything else.
dotenv_load() {
  local file="$1" line key value
  [[ -r "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    line="${line#export }"
    [[ "$line" =~ '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$' ]] || continue
    key="${match[1]}"
    value="${match[2]}"
    if [[ "$value" == \"*\" && ${#value} -ge 2 ]]; then
      value="${value:1:-1}"
    elif [[ "$value" == \'*\' && ${#value} -ge 2 ]]; then
      value="${value:1:-1}"
    fi
    export "$key=$value"
  done <"$file"
}

# dotenv_load_dotfiles [root] [overlay]: load <root>/.env, then <overlay>/.env,
# so the overlay wins. Defaults: $DOTFILES and the private overlay.
dotenv_load_dotfiles() {
  local root="${1:-$DOTFILES}"
  local overlay="${2:-${DOTFILES_PRIVATE:-$DOTFILES/private}}"
  dotenv_load "$root/.env"
  dotenv_load "$overlay/.env"
}
