#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

running "gems..."
if test $(which gem)
then
  ok "gems"
  gem install $(cat $DOTFILES/ruby/gems|grep -v "#")
  ok "gems installed\n"
fi
