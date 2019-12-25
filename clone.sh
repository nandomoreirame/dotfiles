#!/bin/sh

if [ ! -d "$HOME/.dotfiles" ]; then
  echo "Installing dotfiles for the first time"
  git clone --depth=1 https://github.com/nandomoreirame/dotfiles.git "$HOME/.dotfiles"
  cd "$HOME/.dotfiles"
else
  echo ".dotfiles is already cloned"
fi

echo "please execute the command -> sh ~/.dotfiles/install.sh"
