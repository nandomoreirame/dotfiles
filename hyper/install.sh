#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

source "$HOME/dotfiles/common/functions.sh"

rm -rf $HOME/.hyper.js
ln -s $HOME/dotfiles/hyper/hyper.js $HOME/.hyper.js
msg_installing "Linking $HOME/.hyper.js"
