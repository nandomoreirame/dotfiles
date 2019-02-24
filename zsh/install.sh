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

# Installing zsh-autosuggestions
msg_installing "Installing zsh-autosuggestions plugin..."
rm -rf $HOME/dotfiles/zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Installing zsh-syntax-highlighting
msg_installing "Installing zsh-syntax-highlighting plugin..."
rm -rf $HOME/dotfiles/zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Installing pure
msg_installing "Installing pure theme..."
rm -rf $HOME/dotfiles/zsh/custom/themes/pure-zsh-theme
sudo rm -rf /usr/local/share/zsh/site-functions/prompt_pure_setup
sudo rm -rf /usr/local/share/zsh/site-functions/async
git clone https://github.com/belak/pure-zsh-theme.git $HOME/.oh-my-zsh/custom/themes/pure-zsh-theme
sudo ln -s "$HOME/.oh-my-zsh/custom/themes/pure-zsh-theme/pure.zsh" /usr/local/share/zsh/site-functions/prompt_pure_setup
sudo ln -s "$HOME/.oh-my-zsh/custom/themes/pure-zsh-theme/async.zsh" /usr/local/share/zsh/site-functions/async