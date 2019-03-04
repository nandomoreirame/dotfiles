#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "$HOME/dotfiles/common/functions.sh"

msg_installing "gems..."
if test $(which gem)
then
  msg_checking "gems"
  gem install $(cat ~/dotfiles/ruby/gems|grep -v "#")
  msg_ok "gems installed\n"
fi
