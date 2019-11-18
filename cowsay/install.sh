#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

# Linking cowfiles folder...
msg_installing "Linking cowfiles folder..."
rm -rf $HOME/cowfiles
ln -s $HOME/dotfiles/cowsay $HOME/cowfiles
