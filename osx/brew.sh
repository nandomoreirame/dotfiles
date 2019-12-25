#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

# --------------–-------–--------–--------–-------–--–-----
# System packages
# --------------–-------–--------–--------–-------–--–-----
# Install Homebrew for package management, if not installed
if test ! $(which brew)
then
  running "brew"
  running "Homebrew for package management..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  ok "brew"
fi

running "update and upgrade Homebrew..."
# Make sure Homebrew is up to date
brew update
brew upgrade

# Command-line tools and utils
# --------------–-------–--------–--------–-------–--–-----
running "packages using Homebrew..."
brew install $(cat $DOTFILES/osx/brewfile | grep -v "#")

# Remove outdated versions from the cellar.
# --------------–-------–--------–--------–-------–--–-----
brew cleanup
