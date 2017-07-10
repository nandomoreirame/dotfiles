#!/bin/bash
# Personal information in your .gitlocal, not .gitconfig!

cd "$(dirname "${BASH_SOURCE[0]}")" \
    && . "../functions.sh"

debugging "Linking Git dotfiles..."

rm -rf $HOME/.gitconfig $HOME/.gitattributes $HOME/.gitignore_global
ln -s $HOME/.files/git/config $HOME/.gitconfig
ln -s $HOME/.files/git/attributes $HOME/.gitattributes
ln -s $HOME/.files/git/ignore_global $HOME/.gitignore_global

color=`tput setaf 6`
reset=`tput sgr0`

echo -n "${color}Enter your git email: ${reset}"
read GIT_EMAIL
echo -n "${color}Enter your git name: ${reset}"
read GIT_NAME

echo "[user]
  email = $GIT_EMAIL\n
  name = $GIT_NAME" > $HOME/.gitconfig.local
