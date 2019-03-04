#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

rm -rf $HOME/.bashrc
ln -s $HOME/dotfiles/common/bashrc $HOME/.bashrc
msg_ok "$HOME/.bashrc"

rm -rf $HOME/.bash_profile
ln -s $HOME/dotfiles/common/bash_profile $HOME/.bash_profile
msg_ok "$HOME/.bash_profile"

rm -rf $HOME/.profile
ln -s $HOME/dotfiles/common/profile $HOME/.profile
msg_ok "$HOME/.profile"

rm -rf $HOME/.curlrc
ln -s $HOME/dotfiles/common/curlrc $HOME/.curlrc
msg_ok "$HOME/.curlrc"

rm -rf $HOME/.wgetrc
ln -s $HOME/dotfiles/common/wgetrc $HOME/.wgetrc
msg_ok "$HOME/.wgetrc"
