#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

rm -rf $HOME/Library/Application\ Support/Code\ -\ Insiders/User/*.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
ln -s $HOME/dotfiles/vscode/osx/settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
ln -s $HOME/dotfiles/vscode/osx/keybindings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/keybindings.json
ln -s $HOME/dotfiles/vscode/snippets $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
ln -s $HOME/dotfiles/vscode/vsicons.settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/vsicons.settings.json

msg_ok "VSCode settings..."