#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "$HOME/dotfiles/common/functions.sh"

# Installing zsh-autosuggestions
msg_installing "Installing zsh-autosuggestions plugin..."
rm -rf $HOME/dotfiles/zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Installing zsh-syntax-highlighting
msg_installing "Installing zsh-syntax-highlighting plugin..."
rm -rf $HOME/dotfiles/zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Installing spaceship-prompt theme
msg_installing "Installing spaceship-prompt theme..."
rm -rf $HOME/dotfiles/zsh/custom/themes/spaceship-prompt
git clone https://github.com/denysdovhan/spaceship-prompt.git $HOME/.oh-my-zsh/custom/themes/spaceship-prompt
sudo ln -s "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
