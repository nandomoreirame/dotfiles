#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"
source common/utils.sh

if [ "$(uname)" == "Darwin" ]; then
  if test $(which subl)
  then
    msg_installing "Linking Sublime Text 3 settings..."
    rm -rf ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
    ln -s ~/dotfiles/sublime/User ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
    rm -rf ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings
    ln -s ~/dotfiles/sublime/osx/Preferences ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings
  fi
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  msg_installing "Instaling Sublime Text 3..."
  add-repository ppa:webupd8team/sublime-text-3
  update
  install_package sublime-text-installer

  if test $(which subl)
  then
    msg_checking "Sublime text"
    msg_installing "Linking Sublime Text 3 settings..."
    rm -rf ~/.config/sublime-text-3/Packages/User
    ln -s ~/dotfiles/sublime/User ~/.config/sublime-text-3/Packages/User
    rm -rf ~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings
    ln -s ~/dotfiles/sublime/linux/Preferences ~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings
  fi
fi
