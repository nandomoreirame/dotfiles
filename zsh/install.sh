#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "$HOME/dotfiles/common/functions.sh"

# Installing oh-my-zsh
msg_installing "oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Linking ZSH settings...
msg_installing "Linking ZSH settings..."
rm -rf $HOME/.zshrc $HOME/.oh-my-zsh/custom
ln -s $HOME/dotfiles/zsh/zshrc.sh $HOME/.zshrc
ln -s $HOME/dotfiles/zsh/custom $HOME/.oh-my-zsh/custom
