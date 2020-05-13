#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

rm -rf $HOME/Library/Application\ Support/Code/User/*.json $HOME/Library/Application\ Support/Code/User/snippets
ln -s $DOTFILES/vscode/osx/settings.json $HOME/Library/Application\ Support/Code/User/settings.json
ln -s $DOTFILES/vscode/osx/keybindings.json $HOME/Library/Application\ Support/Code/User/keybindings.json
ln -s $DOTFILES/vscode/snippets $HOME/Library/Application\ Support/Code/User/snippets
ln -s $DOTFILES/vscode/vsicons.settings.json $HOME/Library/Application\ Support/Code/User/vsicons.settings.json
rm -rf $HOME/.vscode/extensions.json && ln -s $DOTFILES/vscode/extensions.json $HOME/.vscode/extensions.json
bot ""

rm -rf $HOME/Library/Application\ Support/Code\ -\ Insiders/User/*.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
ln -s $DOTFILES/vscode/osx/settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/settings.json
ln -s $DOTFILES/vscode/osx/keybindings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/keybindings.json
ln -s $DOTFILES/vscode/snippets $HOME/Library/Application\ Support/Code\ -\ Insiders/User/snippets
ln -s $DOTFILES/vscode/vsicons.settings.json $HOME/Library/Application\ Support/Code\ -\ Insiders/User/vsicons.settings.json
rm -rf $HOME/.vscode/extensions.json && ln -s $DOTFILES/vscode/extensions.json $HOME/.vscode/extensions.json
bot ""
