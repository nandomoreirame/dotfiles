#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

if [ "$(uname)" == "Darwin" ]; then
  debugging "Linking Sublime Text 3 settings on MacOS..."
  rm -rf ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
  ln -s ~/.files/sublime/User ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
  rm -rf ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings
  ln -s ~/.files/sublime/osx/Preferences ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  debugging "Instaling Sublime Text 3 on Linux..."
  sudo add-apt-repository ppa:webupd8team/sublime-text-3 -qqy
  sudo apt-get update -qqy
  sudo apt-get install sublime-text-installer -qqy

  debugging "Linking Sublime Text 3 settings on Linux..."
  rm -rf ~/.config/sublime-text-3/Packages/User
  ln -s ~/.files/sublime/User ~/.config/sublime-text-3/Packages/User
  rm -rf ~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings
  ln -s ~/.files/sublime/linux/Preferences ~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings
fi
