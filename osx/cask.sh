#!/bin/bash

# Ask for the administrator password upfront
sudo -v

if [ -x "functions.sh" ]; then
  . "functions.sh" || exit 1
fi

source "$HOME/dotfiles/common/functions.sh"

msg_installing "programs using Homebrew-cask..."
brew cask install $(cat ~/dotfiles/osx/brewcask | grep -v "#")
msg_ok $(cat ~/dotfiles/osx/brewcask | grep -v "#")
