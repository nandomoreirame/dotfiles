#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

# Installing dependencies for OS
running "dependencies for OSx..."

$DOTFILES/osx/brew.sh
$DOTFILES/osx/cask.sh
$DOTFILES/osx/defaults.sh

bot ""
