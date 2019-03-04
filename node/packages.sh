#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

rm -rf $NVM_DIR/default-packages
ln -s $HOME/dotfiles/node/default-packages $NVM_DIR/default-packages
msg_ok "$NVM_DIR/default-packages"
