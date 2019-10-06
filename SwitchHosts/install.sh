#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

rm -rf $HOME/.SwitchHosts
ln -s $HOME/dotfiles/SwitchHosts $HOME/.SwitchHosts
msg_ok "$HOME/.SwitchHosts"
