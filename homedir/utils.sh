#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

update () {
  running "Updating OS..."
  sudo apt-get update -qqy
}

upgrade () {
  running "Upgrading OS..."
  export DEBIAN_FRONTEND="noninteractive" \
    && sudo apt-get -o Dpkg::Options::="--force-confnew" upgrade -qqy
}

install_package () {
  running "$1..."
  sudo apt-get install $1 -qqy
}

add_repository () {
  running "$1..."
  sudo add-apt-repository $1 -qqy
}
