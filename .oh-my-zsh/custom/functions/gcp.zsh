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
