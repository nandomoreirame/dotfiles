#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

NODE_VERSION=10
NVMRC_FILE="$HOME/.nvmrc"

rm -rf $NVMRC_FILE && echo "$NODE_VERSION" > $NVMRC_FILE

msg_installing "nvm"
curl -o- -s https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
msg_installed "nvm"

nvm use
nvm install $NODE_VERSION
nvm alias default $NODE_VERSION
node -v
msg_ok "$NVMRC_FILE"
