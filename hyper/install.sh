#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

source "$HOME/dotfiles/common/functions.sh"

msg_installing "Linking ~/.hyper.js"

rm -rf $HOME/.hyper.js
ln -s $HOME/dotfiles/hyper/hyper.js $HOME/.hyper.js
