#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

rm -rf $NVM_DIR/default-packages
ln -s $DOTFILES/node/default-packages $NVM_DIR/default-packages
ok "$NVM_DIR/default-packages"
