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
