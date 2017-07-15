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

  # Installing zsh
  ./zsh/install.sh

  # Installing sublime text 3
  ./sublime/install.sh

  # Installing vscode
  ./vscode/install.sh

  # Installing NVM, NodeJS and Node modules
  ./node/install.sh

  # Installing git settings
  ./git/install.sh

  rm -rf $HOME/.bashrc $HOME/.bash_profile $HOME/.profile $HOME/.curlrc $HOME/.wgetrc
  ln -s $HOME/.files/.bashrc $HOME/.bashrc
  ln -s $HOME/.files/.bash_profile $HOME/.bash_profile
  ln -s $HOME/.files/.profile $HOME/.profile
  ln -s $HOME/.files/.curlrc $HOME/.curlrc
  ln -s $HOME/.files/.wgetrc $HOME/.wgetrc
}

main "$@"