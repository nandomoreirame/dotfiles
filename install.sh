#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v

# --------------–-------–--------–--------–-------–--–-----
# System packages
# --------------–-------–--------–--------–-------–--–-----
# Install Homebrew for package management, if not installed
if test ! $(which brew)
then
  echo " → Installing Homebrew for package management..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Make sure Homebrew is up to date
brew update
brew upgrade
