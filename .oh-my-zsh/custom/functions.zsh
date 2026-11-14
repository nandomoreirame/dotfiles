# Generic shell helpers.
# Author AI wrappers (claude/codex/commit with permissions disabled) and
# chrome-insecure live in private/shell/, not here.

source "$DOTFILES/lib/functions.sh"

# Run <cmd...> in the background with a spinner on stderr. Capture wait status
# before any other command so the exit code is preserved.
_run_with_spinner() {
  local msg="$1"
  shift
  local out pid ret
  local spin=('|' '/' '-' '\')
  local i=0 n=${#spin[@]} idx

  out=$(mktemp -t spinner.XXXXXX) || return 1
  setopt local_options no_monitor
  "$@" >"$out" 2>&1 &
  pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    idx=$((i % n + 1))
    printf >&2 '\r\033[2K\033[33m%s\033[0m %s' "${spin[idx]}" "$msg"
    sleep 0.08
    ((i++))
  done
  printf >&2 '\r\033[2K'
  wait "$pid"
  ret=$?
  printf >&2 '\n'
  cat "$out"
  rm -f "$out"
  return ret
}

cd() {
  z "$@" && ll
}

_http_request() {
  local method="$1"
  local url="$2"
  local body="$3"
  local cmd="http.${(L)method}"

  if [ -z "$url" ]; then
    e_error "URL is required"
    case "$method" in
      DELETE)
        e_info "  Usage: ${cmd} <url>"
        e_info "  Example: ${cmd} https://api.example.com/data"
        ;;
      *)
        e_info "  Usage: ${cmd} <url> [body]"
        e_info "  Example: ${cmd} https://api.example.com/data"
        ;;
    esac
    return 1
  fi

  case "$method" in
    GET)
      if [ -z "$body" ]; then
        curl -s "$url" | jq -r '.content'
      else
        curl -s "$url" -d "$body" | jq -r '.content'
      fi
      ;;
    POST|PUT)
      if [ -z "$body" ]; then
        curl -s -X "$method" -H "Content-Type: application/json" "$url" | jq -r '.content'
      else
        curl -s -X "$method" -H "Content-Type: application/json" -d "$body" "$url" | jq -r '.content'
      fi
      ;;
    DELETE)
      curl -s -X DELETE "$url" | jq -r '.content'
      ;;
  esac
}

http.get() {
  _http_request GET "$@"
}

http.post() {
  _http_request POST "$@"
}

http.put() {
  _http_request PUT "$@"
}

http.delete() {
  _http_request DELETE "$@"
}

# Accelerated multi-connection download via aria2.
# Pre-configured for max parallelism (-x/-s 16), 1M min segment and resume (-c).
# Extra aria2c flags (e.g. -d ~/Downloads) can be appended after the URL.
download() {
  if [ -z "$1" ]; then
    e_error "URL is required"
    e_info "  Usage: download <url> [aria2c options]"
    e_info "  Example: download https://example.com/file.iso"
    e_info "  Example: download https://example.com/file.iso -d ~/Downloads"
    return 1
  fi

  command aria2c -x 16 -s 16 -k 1M -c "$@"
}

# Set the active gcloud project. Requires an argument or $PROJECT_ID.
function gcp-set-project() {
  local project_id="$1"

  if [ -z "$project_id" ]; then
    project_id="${PROJECT_ID:-}"
  fi

  if [ -z "$project_id" ]; then
    e_error "usage: gcp-set-project <project-id>"
    return 1
  fi

  e_info "Revoking GCP application-default credentials..."
  echo "Y" | gcloud auth application-default revoke > /dev/null 2>&1
  e_success "Revoked application-default credentials"

  e_info "Logging in to GCP..."
  gcloud auth application-default login > /dev/null 2>&1
  e_success "Logged in to GCP"

  e_info "Setting GCP project..."
  gcloud config set project "$project_id" > /dev/null 2>&1
  e_success "Set GCP project \"${project_id}\""

  e_info "Setting GCP quota project..."
  gcloud auth application-default set-quota-project "$project_id" > /dev/null 2>&1
  e_success "Set GCP quota project \"${project_id}\""

  export PROJECT_ID="$project_id"
  e_info "GCP project set to \"${PROJECT_ID}\""
}
