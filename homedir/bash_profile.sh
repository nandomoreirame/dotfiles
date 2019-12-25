# ~/.bash_profile

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
export GPG_TTY=$(tty)