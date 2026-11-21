# git push/pull with a spinner while the network call runs.
push() {
  _run_with_spinner "Pushing..." command git push "$@"
}

pull() {
  _run_with_spinner "Pulling..." command git pull "$@"
}
