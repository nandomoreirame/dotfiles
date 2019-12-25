#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

if type "npm" > /dev/null; then
  ok "npm installed!"
  if ! type "cowsay" > /dev/null; then
    running "installing cowsay"
    npm install -g cowsay
  else
    ok "cowsay installed!"
  fi
fi

# Linking cowfiles folder...
running "Linking cowfiles folder..."
rm -rf $HOME/cowfiles
ln -s $DOTFILES/cowsay $HOME/cowfiles

bot ""
