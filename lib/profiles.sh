#!/usr/bin/env bash

# ============================================
# Profiles management library (loader)
# ============================================
# Loads core, git and gcloud profile modules.

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/environments.sh
source "$DOTFILES/lib/environments.sh"
# shellcheck source=lib/validation.sh
source "$DOTFILES/lib/validation.sh"

# ============================================
# Configuration
# ============================================

PROFILES_DIR="${PROFILES_DIR:-$DOTFILES/profiles}"
CURRENT_PROFILE_FILE="${CURRENT_PROFILE_FILE:-$DOTFILES/profiles/.current}"
CURRENT_GIT_CONFIG_FILE="${CURRENT_GIT_CONFIG_FILE:-$DOTFILES/profiles/.current-git}"
CURRENT_GCLOUD_CONFIG_FILE="${CURRENT_GCLOUD_CONFIG_FILE:-$DOTFILES/profiles/.current-gcloud}"

# shellcheck source=lib/profiles/core.sh
source "$DOTFILES/lib/profiles/core.sh"
# shellcheck source=lib/profiles/git.sh
source "$DOTFILES/lib/profiles/git.sh"
# shellcheck source=lib/profiles/gcloud.sh
source "$DOTFILES/lib/profiles/gcloud.sh"
