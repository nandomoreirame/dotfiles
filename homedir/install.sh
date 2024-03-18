#!/bin/bash

source "`dirname $0`"/../lib/colors.sh
source "`dirname $0`"/../lib/enviroments.sh

files=(".bash_history" ".bash_profile" ".bashrc" ".curlrc" ".prettierignore" ".prettierrc.json" ".profile" ".rvmrc" ".wgetrc" ".zsh_history")

for file in "${files[@]}"
do
	rm -rf $HOME/$file
	ln -s $DOTFILES/homedir/$file $HOME/$file
	ok "$HOME/${file}"
done

bot ""
