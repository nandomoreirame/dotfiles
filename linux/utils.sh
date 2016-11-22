#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

update () {
  debugging "Updating OS..."
  sudo apt-get update -qqy
}

upgrade () {
  debugging "Upgrading OS..."
  export DEBIAN_FRONTEND="noninteractive" \
    && sudo apt-get -o Dpkg::Options::="--force-confnew" upgrade -qqy
}

install_package () {
  debugging "Installing $1..."
  sudo apt-get install $1 -qqy
}
