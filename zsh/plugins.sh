#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

# Installing zsh-autosuggestions
running "Installing zsh-autosuggestions plugin..."
rm -rf $DOTFILES/zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions $DOTFILES/zsh/custom/plugins/zsh-autosuggestions

# Installing zsh-syntax-highlighting
running "Installing zsh-syntax-highlighting plugin..."
rm -rf $DOTFILES/zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $DOTFILES/zsh/custom/plugins/zsh-syntax-highlighting

# Installing spaceship-prompt theme
running "Installing spaceship-prompt theme..."
rm -rf $DOTFILES/zsh/custom/themes/spaceship-prompt $DOTFILES/zsh/custom/themes/spaceship.zsh-theme
git clone https://github.com/denysdovhan/spaceship-prompt.git $DOTFILES/zsh/custom/themes/spaceship-prompt
sudo ln -s "$DOTFILES/zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$DOTFILES/zsh/custom/themes/spaceship.zsh-theme"
