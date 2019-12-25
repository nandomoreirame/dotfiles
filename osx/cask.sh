#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

running "programs using Homebrew-cask..."
brew cask install $(cat $DOTFILES/osx/brewcask | grep -v "#")
ok $(cat $DOTFILES/osx/brewcask | grep -v "#")
