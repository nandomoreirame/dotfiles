#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

source "$HOME/dotfiles/common/functions.sh"

msg_installing "Linking Git dotfiles..."

rm -rf $HOME/.gitconfig $HOME/.gitattributes $HOME/.gitignore_global
ln -s $HOME/dotfiles/git/config $HOME/.gitconfig
ln -s $HOME/dotfiles/git/attributes $HOME/.gitattributes
ln -s $HOME/dotfiles/git/ignore_global $HOME/.gitignore_global

# msg "Enter your git name: "
# read GIT_NAME
# msg "Enter your git email: "
# read GIT_EMAIL

# echo "[user]
#   email = $GIT_EMAIL
#   name = $GIT_NAME" > $HOME/.gitconfig.local
