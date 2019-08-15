#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

# is Insiders ?
echo "is Visual Studio Code - Insiders? (y or n)"
read isInsiders;

if [ "$isInsiders" = "y" ];
then
  rm -rf $HOME/Library/Application\ Support/Code\ -\ Insiders/User/*.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
  ln -s $HOME/dotfiles/vscode/osx/settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
  ln -s $HOME/dotfiles/vscode/osx/keybindings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/keybindings.json
  ln -s $HOME/dotfiles/vscode/snippets $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
  ln -s $HOME/dotfiles/vscode/vsicons.settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/vsicons.settings.json
  msg_ok "Visual Studio Code - Insiders settings..."
else
  rm -rf $HOME/Library/Application\ Support/Code/User/*.json $HOME/Library/Application\ Support/Code/User/snippets
  ln -s $HOME/dotfiles/vscode/osx/settings.json $HOME/Library/Application\ Support/Code/User/settings.json
  ln -s $HOME/dotfiles/vscode/osx/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
  ln -s $HOME/dotfiles/vscode/snippets $HOME/Library/Application\ Support/Code/User/snippets
  ln -s $HOME/dotfiles/vscode/vsicons.settings.json $HOME/Library/Application\ Support/Code/User/vsicons.settings.json
  msg_ok "Visual Studio Code settings..."
fi

