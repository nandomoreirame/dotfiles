#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "$HOME/dotfiles/common/functions.sh"

RUBY_VERSION=2.3.3

rm -rf $HOME/.rvm
rm -rf $HOME/.rvmrc

msg_installing "Ruby Version Manager (RVM) ..."
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.profile

if test $(which rvm)
then
  msg_checking "rvm"
  msg_installing "rvm requirements and ruby..."
  rvm requirements
  rvm install ruby-$RUBY_VERSION
  rvm use ruby-$RUBY_VERSION
  rvm rubygems current
  msg_ok "rvm requirements and ruby"
fi

echo "$RUBY_VERSION" > $HOME/.rvmrc
msg_ok "$HOME/.rvmrc"