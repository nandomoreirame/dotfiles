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
