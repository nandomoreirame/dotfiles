#!/bin/bash

# Ask for the administrator password upfront
sudo -v

if [ -x "functions.sh" ]; then
  . "functions.sh" || exit 1
fi

source "$HOME/dotfiles/common/functions.sh"

# --------------–-------–--------–--------–-------–--–-----
# System packages
# --------------–-------–--------–--------–-------–--–-----
# Install Homebrew for package management, if not installed
if test ! $(which brew)
then
  msg_installing "brew"
  msg_installing "Homebrew for package management..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  msg_ok "brew"
fi

msg_installing "update and upgrade Homebrew..."
# Make sure Homebrew is up to date
brew update
brew upgrade

# Command-line tools and utils
# --------------–-------–--------–--------–-------–--–-----
msg_installing "packages using Homebrew..."
brew install $(cat ~/dotfiles/osx/brewfile | grep -v "#")

# Remove outdated versions from the cellar.
# --------------–-------–--------–--------–-------–--–-----
brew cleanup