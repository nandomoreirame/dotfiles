#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

debugging "Linking ~/.hyper.js"

rm -rf $HOME/.hyper.js
ln -s $HOME/.files/hyper/hyper.js $HOME/.hyper.js
