#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v

if [ -x "functions.sh" ]; then
  . "functions.sh" || exit 1
fi

source "$HOME/dotfiles/common/functions.sh"

main() {

  # $HOME/dotfiles/osx/install.sh

  # Installing vscode
  $HOME/dotfiles/vscode/install.sh

  # Installing NVM, NodeJS and Node modules
  $HOME/dotfiles/node/install.sh

  # Installing git settings
  $HOME/dotfiles/git/install.sh

  # Installing Hyper settings
  $HOME/dotfiles/hyper/install.sh

  # Installing zsh
  $HOME/dotfiles/zsh/install.sh

  # Installing common files
  $HOME/dotfiles/common/install.sh

}

main "$@"