#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

rm -rf $HOME/.hyper.js
ln -s $DOTFILES/hyper/hyper.js $HOME/.hyper.js
running "Linking $HOME/.hyper.js"
bot ""
