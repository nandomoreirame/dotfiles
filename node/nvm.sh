#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

NODE_VERSION=10
NVM_FOLDER="$HOME/.nvm"
NVMRC_FILE="$DOTFILES/.nvmrc"

rm -rf $NVMRC_FILE $HOME/.nvmrc
echo "$NODE_VERSION" > $NVMRC_FILE
ln -s $NVMRC_FILE $HOME/.nvmrc
ok "$NVMRC_FILE"

if [ -d $NVM_FOLDER  ]
then
  ok "The directory $NVM_FOLDER already exists!"
else
  running "Instalando NVM..."
  curl -o- -s https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
  ok "nvm"

  # nvm
  if test $(which nvm)
  then
    bot "NVM installed!"
    nvm install $NODE_VERSION
    nvm use
    nvm alias default $NODE_VERSION
    node -v
  fi
fi
