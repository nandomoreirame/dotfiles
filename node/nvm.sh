#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

NODE_VERSION=10
NVM_FOLDER="$HOME/.nvm"
NVMRC_FILE="$HOME/dotfiles/.nvmrc"

rm -rf $NVMRC_FILE
echo "$NODE_VERSION" > $NVMRC_FILE
ln -s $NVMRC_FILE $HOME/.nvmrc
msg_ok "$NVMRC_FILE"

if [ -d $NVM_FOLDER  ]
then
  echo "Directory $NVM_FOLDER exists!"
else
  msg_installing "nvm"
  curl -o- -s https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
  msg_installed "nvm"

  # nvm
  if test $(which nvm)
  then
    msg_checking "nvm"
    nvm install $NODE_VERSION
    nvm use
    nvm alias default $NODE_VERSION
    node -v
  fi
fi
