# Easy folders navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Always recursive and verbose
alias cp="cp -r"
alias rm="rm -rf"
alias mv="mv -v"

# List all files colorized in long format
alias l="ls -l -G"
alias ls-a="ls -a -G"
# List all files colorized in long format, including dot files
alias la="ls -la -G"
# List only directories
alias lsd='ls -l -G | grep "^d"'
# Always use color output for `ls`
alias ls="command ls -G"

# Process status
alias psa="ps aux"
alias ht="htop"

# Easy folder and file loading
alias www="cd ~/Sites"
alias cl="cd ~/Sites/clients"
alias ops="cd ~/Sites/open-source"
alias pld="cd ~/Sites/playground"
alias projects="cd ~/Sites/projects"
alias dl="cd ~/Downloads"
alias apps="cd /Applications"
alias files="cd ~/.files"

alias zload="source ~/.zshrc"
alias finder='open . -a finder.app'

# Miscellaneous
alias cleanup="find  -type f -name '*DS_Store' -ls -delete"
alias kll="killall"
alias h="history"
alias q="exit"

# Find the largest file under current directory
alias largestf='find -type f -printf '\''%s %p\n'\'' | sort -nr | head -n 40 | gawk "{ print \$1/1000000 \" \" \$2 \" \" \$3 \" \" \$4 \" \" \$5 \" \" \$6 \" \" \$7 \" \" \$8 \" \" \$9 }"'

# Show the external IP
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# Check web page download time
alias curltime='curl -s -w "%{time_total} seconds\n" -o /dev/null'

# Git and GitHub (hub.github.com)
alias g="git"
alias gs="git status"
# alias git="hub"
# alias gh="hub"
alias chucknorris="sudo"
alias s="subl"
alias c="code"
alias d="docker"
alias dc="docker-compose"
alias gp="gulp"
alias gw="gulp watch"
