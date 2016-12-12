#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

debugging "Linking VIM dotfiles..."

rm -rf $HOME/.vim $HOME/.gitattributes $HOME/.vim
rm -rf $HOME/.vimrc $HOME/.gitattributes $HOME/.vimrc

ln -s $HOME/.files/vim $HOME/.vim
ln -s $HOME/.files/vim/vimrc $HOME/.vimrc
