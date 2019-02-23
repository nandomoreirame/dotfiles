#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

msg_installing "Linking VSCode settings..."

if [ "$(uname)" == "Darwin" ]; then
  rm -rf $HOME/Library/Application\ Support/Code\ -\ Insiders/User/*.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
  ln -s $HOME/dotfiles/vscode/osx/settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
  ln -s $HOME/dotfiles/vscode/osx/keybindings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/keybindings.json
  ln -s $HOME/dotfiles/vscode/snippets $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
  ln -s $HOME/dotfiles/vscode/vsicons.settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/vsicons.settings.json
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  rm -rf $HOME/.config/Code/User/*.json $HOME/.config/Code/User/snippets
  ln -s $HOME/dotfiles/vscode/linux/settings.json $HOME/.config/Code/User/settings.json
  ln -s $HOME/dotfiles/vscode/linux/keybindings.json $HOME/.config/Code/User/keybindings.json
  ln -s $HOME/dotfiles/vscode/snippets $HOME/.config/Code/User/snippets
  ln -s $HOME/dotfiles/vscode/vsicons.settings.json $HOME/.config/Code/User/vsicons.settings.json
fi
