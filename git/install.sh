#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

debugging "Linking Git dotfiles..."

rm -rf $HOME/.gitconfig $HOME/.gitattributes $HOME/.gitignore_global
ln -s $HOME/.files/git/config $HOME/.gitconfig
ln -s $HOME/.files/git/attributes $HOME/.gitattributes
ln -s $HOME/.files/git/ignore_global $HOME/.gitignore_global