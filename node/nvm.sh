#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

NODE_VERSION=10

rm -rf $HOME/.nvm
rm -rf $HOME/.nvmrc

msg_installing "nvm"
curl -o- -s https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
msg_installed "nvm"

# nvm
if test $(which nvm)
then
  msg_checking "nvm"
  nvm install $NODE_VERSION
  echo "$NODE_VERSION" > $HOME/.nvmrc
  nvm use
  nvm alias default $NODE_VERSION
  node -v
  msg_ok "$HOME/.nvmrc"
fi