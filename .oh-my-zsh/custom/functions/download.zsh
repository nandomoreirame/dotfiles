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
