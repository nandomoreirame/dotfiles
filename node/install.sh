#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

$DOTFILES/node/nvm.sh
$DOTFILES/node/packages.sh
$DOTFILES/node/npmrc.sh

bot ""
