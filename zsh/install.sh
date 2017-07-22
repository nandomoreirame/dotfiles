#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

# Installing oh-my-zsh
debugging "Installing oh-my-zsh..."
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh

# Linking ZSH settings...
debugging "Linking ZSH settings..."
rm -rf $HOME/.zshrc $HOME/.oh-my-zsh/custom
ln -s $HOME/.files/zsh/zshrc $HOME/.zshrc
ln -s $HOME/.files/zsh/custom $HOME/.oh-my-zsh/custom

# Installing zsh-autosuggestions
debugging "Installing zsh-autosuggestions..."
rm -rf $HOME/.files/zsh/custom/plugins/zsh-autosuggestions
git clone git://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
