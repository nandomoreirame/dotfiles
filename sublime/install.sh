#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

if [ "$(uname)" == "Darwin" ]; then
  debugging "Linking Sublime Text 3 settings on MacOS X..."
  rm -rf ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
  ln -s ~/.files/sublime/User ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  debugging "Linking Sublime Text 3 settings on Linux..."
  rm -rf ~/.config/sublime-text-3/Packages/User
  ln -s ~/.files/sublime/User ~/.config/sublime-text-3/Packages/User
fi
