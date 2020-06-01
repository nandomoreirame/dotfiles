#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

NPMRC_FILE="$DOTFILES/node/.npmrc"

rm -rf $NPMRC_FILE $HOME/.npmrc

NPM_INIT_NAME="Fernando Moreira"
NPM_INIT_EMAIL="nandomoreira.me@gmail.com"
NPM_INIT_URL="https://nandomoreira.dev/"
NPM_INIT_VERSION="1.0.0"
NPM_INIT_LICENSE="MIT"

echo "init.author.name=$NPM_INIT_NAME
init.author.email=$NPM_INIT_EMAIL
init.author.url=$NPM_INIT_URL
init.version=$NPM_INIT_VERSION
init.license=$NPM_INIT_LICENSE" > $NPMRC_FILE

ln -s $NPMRC_FILE $HOME/.npmrc

ok "successfully created file $NPMRC_FILE"

echo "registry \"https://registry.npmjs.org/\"
lastUpdateCheck 0" > "$HOME/.yarnrc"
