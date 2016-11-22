#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v

if [ -x "functions.sh" ]; then
  . "functions.sh" || exit 1
fi

main() {

  # Installing dependencies for OS
  if [ "$(uname)" == "Darwin" ]; then
    debugging "Installing dependencies for OSx..."
    ./osx/install.sh
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    debugging "Installing dependencies for Linux..."
    ./linux/install.sh
  fi

  # Installing git settings
  ./git/install.sh

  # Installing zsh settings
  ./zsh/install.sh

  # Installing sublime settings
  ./sublime/install.sh

  # Installing vscode settings
  ./vscode/install.sh

}

main "$@"