#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

NODE_VERSION=6

if test $(which curl)
then
  debugging "Installing NVM and NodeJS..."
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
fi

# nvm
if test $(which nvm)
then
  nvm install $NODE_VERSION
  rm -rf $HOME/.nvmrc
  echo "$NODE_VERSION" > $HOME/.nvmrc
  nvm use
fi

debugging "Installing npm packages..."

# npm
if test $(which npm)
then
  npm install -g yarn
  yarn global add $(cat globals|grep -v "#")
fi

rm -rf $HOME/.npmrc

echo -n "${color}npm init name: ${reset}"
read NPM_INIT_NAME
echo -n "${color}npm init email: ${reset}"
read NPM_INIT_EMAIL
echo -n "${color}npm init utl: ${reset}"
read NPM_INIT_URL

echo "init.author.name=$NPM_INIT_NAME
init.author.email=$NPM_INIT_EMAIL
init.author.url=$NPM_INIT_URL
init.version=0.0.1
init.license=MIT" > $HOME/.npmrc