#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "$HOME/dotfiles/common/functions.sh"

sudo rm -rf /tmp/chrome
sudo ln -s $HOME/dotfiles/browsers/chrome /tmp/chrome
msg_ok "/tmp/chrome"

sudo rm -rf /tmp/canary
sudo ln -s $HOME/dotfiles/browsers/canary /tmp/canary
msg_ok "/tmp/canary"

sudo rm -rf /tmp/chromium
sudo ln -s $HOME/dotfiles/browsers/chromium /tmp/chromium
msg_ok "/tmp/chromium"
