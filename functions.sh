#!/bin/sh

# Ask for the administrator password upfront
sudo -v

debugging () {
  green=`tput setaf 2`
  reset=`tput sgr0`
  echo "${green} ===→ $1${reset}"
}

getOS () {
  if [ "$(uname)" == "Darwin" ]
  then
    return 'osx'
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ];
  then
    return 'linux'
  fi
}