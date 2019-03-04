#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

msg_installing "npm packages... \n"

if test $(which npm)
then
  npm install -g $(cat ~/dotfiles/node/globals|grep -v "#")
  msg_ok "\nglobal modules installed using npm"
fi
