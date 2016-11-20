#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v

green=`tput setaf 2`
reset=`tput sgr0`

debugging () {
  echo "${green} → $1${reset}"
}

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
