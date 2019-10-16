#!/bin/bash

source "$HOME/dotfiles/common/functions.sh"

rm -rf $HOME/Library/Application\ Support/Code/User/*.json $HOME/Library/Application\ Support/Code/User/snippets
ln -s $HOME/dotfiles/vscode/osx/settings.json $HOME/Library/Application\ Support/Code/User/settings.json
ln -s $HOME/dotfiles/vscode/osx/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
ln -s $HOME/dotfiles/vscode/snippets $HOME/Library/Application\ Support/Code/User/snippets
ln -s $HOME/dotfiles/vscode/vsicons.settings.json $HOME/Library/Application\ Support/Code/User/vsicons.settings.json
rm -rf $HOME/.vscode/extensions.json && ln -s $HOME/dotfiles/vscode/extensions.json $HOME/.vscode/extensions.json
msg_ok "Visual Studio Code settings..."
