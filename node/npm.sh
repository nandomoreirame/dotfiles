#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

NPMRC_FILE="$DOTFILES/node/.npmrc"

rm -rf $NPMRC_FILE $HOME/.npmrc

NPM_REGISTRY="https://registry.npmjs.org/"
NPM_INIT_NAME="Fernando Moreira"
NPM_INIT_EMAIL="nandomoreira.me@gmail.com"
NPM_INIT_URL="https://nandomoreira.dev/"
NPM_INIT_VERSION="0.0.1"
NPM_INIT_LICENSE="MIT"

if [ -x "$(command -v npm)" ]; then
  npm -v

  npm set registry "$NPM_REGISTRY"
  npm get registry

  npm set init.author.name "$NPM_INIT_NAME"
  npm get init.author.name

  npm set init.author.email "$NPM_INIT_EMAIL"
  npm get init.author.email

  npm set init.author.url "$NPM_INIT_URL"
  npm get init.author.url

  npm set init.version "$NPM_INIT_VERSION"
  npm get init.version

  npm set init.license "$NPM_INIT_LICENSE"
  npm get init.license
fi

if [ -x "$(command -v yarn)" ]; then
  yarn -v
  yarn config set registry "$NPM_REGISTRY"
  yarn config set init-author-name "$NPM_INIT_NAME"
  yarn config set init-author-email "$NPM_INIT_EMAIL"
  yarn config set init-author-url "$NPM_INIT_URL"
  yarn config set init-version "$NPM_INIT_VERSION"
  yarn config set init-license "$NPM_INIT_LICENSE"
  yarn config list
fi

echo "registry \"$NPM_REGISTRY\"
lastUpdateCheck 0" > "$HOME/.yarnrc"
