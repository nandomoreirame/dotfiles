#!/usr/bin/env bash

###
# @author Fernando Moreira
###

# Ask for the administrator password upfront
sudo -v
source ./lib/colors.sh
source ./lib/enviroments.sh

main() {
  echo -e "\n"
  read -r -p "Do you want to change MacOS preferences? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/osx/install.sh
  else
    ok "osx skipped..."
  fi

  echo -e "\n"
  read -r -p "You want to install Visual Studio Code Settings? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/vscode/install.sh
  else
    ok "vscode skipped..."
  fi

  echo -e "\n"
  read -r -p "Do you want to install NodeJS Settings? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/node/install.sh
  else
    ok "node skipped..."
  fi

  echo -e "\n"
  read -r -p "Do you want to install Git settings? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/git/install.sh
  else
    ok "git skipped..."
  fi

  echo -e "\n"
  read -r -p "You want to install Hyper.js settings? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/hyper/install.sh
  else
    ok "hyper skipped..."
  fi

  echo -e "\n"
  read -r -p "You want to install ZSH and Oh-My-ZSH settings? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/zsh/install.sh
  else
    ok "zsh skipped..."
  fi

  echo -e "\n"
  read -r -p "Do you want to link the Homedir files? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/homedir/install.sh
  else
    ok "homedir skipped..."
  fi

  echo -e "\n"
  read -r -p "Do you want install cowsay and link cowsay files? [y|n] " response
  if [[ $response =~ (yes|y|Y) ]]; then
    $DOTFILES/cowsay/install.sh
  else
    ok "cowsay skipped..."
  fi
}

main "$@"

bot "All done"
