# Generic aliases. Author-specific wrappers and folder shortcuts live in private/shell/.

# Easy folder navigation
alias "home"="cd $HOME"
alias ".."="cd .."
alias "..."="cd ../.."
alias "...."="cd ../../.."
alias "....."="cd ../../../.."

alias t="tmux"
alias ta="tmux attach -t"
alias tn="tmux new -A -s"
alias tkill="tmux kill-session -t"

# docker
alias dc="docker compose"

# git
alias g=git
alias gs="g status -s"

# reload the interactive shell config
alias zload='echo "sourcing ~/.zshrc" && source ~/.zshrc'

alias finder='nautilus'
alias open='nautilus'
alias explorer='nautilus'

alias copy='rsync -avh --progress --ignore-existing'
alias move='rsync -avh --progress --ignore-existing --remove-source-files'

alias chrome='/usr/bin/google-chrome --new-window'

# Show the external IP
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# Check web page download time
alias curl:t='curl -s -w "%{time_total} seconds\n" -o /dev/null'

alias aliases="print -rl -- ${(k)aliases}"
alias functions="print -rl -- ${(k)functions}"
alias parameters="print -rl -- ${(k)parameters}"

# Editors
alias c="code"
alias ca="cursor-agent"
alias editor="gedit"
alias e="gedit"

# Node helpers
alias npm-check="npx npm-check -u"
alias gitignore="npx gitignore"
alias maildev="npx maildev"
alias project-size="npx cloc . --vcs=git"
# Local-only by default. Widen with: http-server -a 0.0.0.0 ...
alias http-server="npx http-server -a 127.0.0.1 -p 3030 -g --cors"

alias ls="eza -l --icons --hyperlink --group-directories-first --sort=type --group --time-style=long-iso --color=always --no-permissions --no-user"
alias la="ls -a"
alias l="la"

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# `cat` with syntax colors (bat)
alias cat="bat"
alias disks="lsblk"
alias disksf="lsblk -f"

# IP addresses
alias ips="ip a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"

alias ping="prettyping --nolegend"

# Python 3
alias python="python3"
alias py="python3"

# markdownlint (rumdl)
alias markdownlint="rumdl check --config ~/.claude/.rumdl.toml"

# ssh add id_rsa and keyscan bitbucket
alias ssid='ssh-add ~/.ssh/id_rsa && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts'

# Twitch + YouTube chat log from obs-live-hub, in a floating terminal
alias live-chat='live-chat-float'
