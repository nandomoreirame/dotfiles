#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

NPMRC_FILE="$HOME/dotfiles/node/.npmrc"

rm -rf $NPMRC_FILE

NPM_INIT_NAME="Fernando Moreira"
NPM_INIT_EMAIL="nandomoreira.me@gmail.com"
NPM_INIT_URL="https://nandomoreira.me/"
NPM_INIT_VERSION="1.0.0"
NPM_INIT_LICENSE="MIT"

echo "init.author.name=$NPM_INIT_NAME
init.author.email=$NPM_INIT_EMAIL
init.author.url=$NPM_INIT_URL
init.version=$NPM_INIT_VERSION
init.license=$NPM_INIT_LICENSE" > $NPMRC_FILE

ln -s $NVMRC_FILE $HOME/.npmrc

msg_checking "successfully created file $NPMRC_FILE"

echo "registry \"https://registry.npmjs.org/\"
lastUpdateCheck 0" > "$HOME/.yarnrc"
