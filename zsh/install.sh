#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

# Installing oh-my-zsh
running "Installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Linking ZSH settings
running "Linking ZSH settings"
rm -rf $HOME/.zshrc $HOME/.oh-my-zsh/custom
ln -s $DOTFILES/zsh/zshrc.sh $HOME/.zshrc
ln -s $DOTFILES/zsh/custom $HOME/.oh-my-zsh/custom

rm -rf $HOME/.zsh_history
ln -s $DOTFILES/homedir/zsh_history.sh $HOME/.zsh_history
ok "$HOME/.zsh_history"

echo -e "\n"
read -r -p "Install oh-my-zsh plugins? [y|n] " response
if [[ $response =~ (yes|y|Y) ]]; then
  $DOTFILES/zsh/plugins.sh
else
  ok "oh-my-zsh plugins skipped..."
fi

bot ""
