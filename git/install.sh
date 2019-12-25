#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

running "Linking Git .dotfiles..."

rm -rf $HOME/.gitconfig $HOME/.gitattributes $HOME/.gitignore_global
ln -s $DOTFILES/git/config $HOME/.gitconfig
ln -s $DOTFILES/git/attributes $HOME/.gitattributes
ln -s $DOTFILES/git/ignore_global $HOME/.gitignore_global

ok ""
