#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v

green=`tput setaf 2`
reset=`tput sgr0`

debugging () {
  echo "${green} ===→ $1${reset}"
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

# Command-line tools and utils
# --------------–-------–--------–--------–-------–--–-----
debugging "Installing packages using Homebrew..."

# Install all packages listed in the brewfile
brew install $(cat brew/brewfile|grep -v "#")

debugging "Installing programs using Homebrew-cask..."
brew cask install $(cat brew/brewcask|grep -v "#")

# --------------–-------–--------–--------–-------–--–-----
# Specific packages
# --------------–-------–--------–--------–-------–--–-----
# Installing oh-my-zsh
debugging "Installing oh-my-zsh..."
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh

# Node.js
debugging "Installing npm packages..."
# npm install -g $(cat npm/globals|grep -v "#")

# --------------–-------–--------–--------–-------–--–-----
# Command line tweaks, linking stuff
# --------------–-------–--------–--------–-------–--–-----
debugging "Linking Git dotfiles..."
# Personal information in your .gitlocal, not .gitconfig!
rm -rf ~/.gitconfig ~/.gitattributes ~/.gitignore_global
ln -s ~/.files/git/config ~/.gitconfig
ln -s ~/.files/git/attributes ~/.gitattributes
ln -s ~/.files/git/ignore_global ~/.gitignore_global

debugging "Linking VSCode settings..."
rm -rf ~/Library/Application\ Support/Code/User/*.json ~/Library/Application\ Support/Code/User/snippets
ln -s ~/.files/vscode/snippets ~/Library/Application\ Support/Code/User/snippets
ln -s ~/.files/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -s ~/.files/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -s ~/.files/vscode/vsicons.settings.json ~/Library/Application\ Support/Code/User/vsicons.settings.json

debugging "Linking Sublime Text 3 settings..."
rm -rf ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
ln -s ~/.files/sublime/User ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
