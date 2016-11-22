#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

# --------------–-------–--------–--------–-------–--–-----
# System packages
# --------------–-------–--------–--------–-------–--–-----
# Install Homebrew for package management, if not installed
if test ! $(which brew)
then
  debugging "Installing Homebrew for package management..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

debugging "update and upgrade Homebrew..."
# Make sure Homebrew is up to date
brew update
brew upgrade

# Command-line tools and utils
# --------------–-------–--------–--------–-------–--–-----
debugging "Installing packages using Homebrew..."

# Install all packages listed in the brewfile
brew install $(cat brew/brewfile|grep -v "#")

debugging "Installing programs using Homebrew-cask..."
brew cask install $(cat brew/brewcask|grep -v "#")

# --------------–-------–--------–--------–-------–--–-----
# System preferences
# --------------–-------–--------–--------–-------–--–-----
# It'll shut down Terminal!
debugging "Set OS X defaults... (It'll shut down Terminal!)"
sh ./defaults.sh