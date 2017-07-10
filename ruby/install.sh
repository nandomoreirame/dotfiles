#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

RUBY_VERSION=2.3.3

if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  debugging "Installing Ruby..."
  sudo apt-get install ruby ruby-dev -qqy
fi

rm -rf $HOME/.ruby-version
echo "$RUBY_VERSION" > $HOME/.ruby-version

debugging "Installing Ruby Version Manager (RVM) ..."
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.profile

if test $(which rvm)
then
  rvm requirements
  rvm install ruby-$RUBY_VERSION
  rvm use ruby-$RUBY_VERSION
  rvm rubygems current
fi

debugging "Installing gems..."
if test $(which gem)
then
  gem install $(cat gems|grep -v "#")
fi
