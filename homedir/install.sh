#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

rm -rf $HOME/.bashrc
ln -s $DOTFILES/homedir/bashrc.sh $HOME/.bashrc
ok "$HOME/.bashrc"

rm -rf $HOME/.bash_profile
ln -s $DOTFILES/homedir/bash_profile.sh $HOME/.bash_profile
ok "$HOME/.bash_profile"

rm -rf $HOME/.profile
ln -s $DOTFILES/homedir/profile.sh $HOME/.profile
ok "$HOME/.profile"

rm -rf $HOME/.curlrc
ln -s $DOTFILES/homedir/curlrc.sh $HOME/.curlrc
ok "$HOME/.curlrc"

rm -rf $HOME/.wgetrc
ln -s $DOTFILES/homedir/wgetrc.sh $HOME/.wgetrc
ok "$HOME/.wgetrc"

rm -rf $HOME/.bash_history
ln -s $DOTFILES/homedir/bash_history.sh $HOME/.bash_history
ok "$HOME/.bash_history"

rm -rf $HOME/.rvmrc
ln -s $DOTFILES/homedir/rvmrc.sh $HOME/.rvmrc
ok "$HOME/.rvmrc"

bot ""
