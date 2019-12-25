#!/bin/bash

# Ask for the administrator password upfront
sudo -v

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

RUBY_VERSION=2.3.3

rm -rf $HOME/.rvm
rm -rf $HOME/.rvmrc

running "Ruby Version Manager (RVM) ..."
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.profile

if test $(which rvm)
then
  ok "rvm"
  running "rvm requirements and ruby..."
  rvm requirements
  rvm install ruby-$RUBY_VERSION
  rvm use ruby-$RUBY_VERSION
  rvm rubygems current
  ok "rvm requirements and ruby"
fi

echo "$RUBY_VERSION" > $HOME/.rvmrc
ok "$HOME/.rvmrc"
