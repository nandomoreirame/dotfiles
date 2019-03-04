#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

NODE_VERSION=10

# if test $(which curl)
# then
#   msg_checking "curl"
#   msg_installing "NVM and NodeJS..."
#   curl -o- -s https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
#   msg_ok "nvm"
# fi

# nvm
if test $(which nvm)
then
  msg_checking "nvm"
  msg_installing "nvm"
  nvm install $NODE_VERSION
  rm -rf $HOME/.nvmrc
  echo "$NODE_VERSION" > $HOME/.nvmrc
  nvm use
  nvm alias default $NODE_VERSION
  node -v
  msg_ok "$HOME/.nvmrc"
fi