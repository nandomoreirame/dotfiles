# Easy folders navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Always recursive and verbose
alias cp="cp -rv"
alias rm="rm -rf"
alias mv="mv -v"

# pwd
# alias .="pwd"

# git
alias git=hub
alias g=hub
alias gs="g status -s"
alias gpl="g pull"
alias gc="g clone"
alias gac="g add --all && g commit -am"
alias ga="g add --all"
alias gurl="hub browse"
alias gup="g up && git-garbage"
alias gpu=git" push -f origin HEAD^:master"
alias gpm=git" push origin master"
alias greset=git" reset HEAD~"

# gitflow
alias gf="git flow"
alias flow="gf"
alias f-init="gf init"
# gitflow feature
alias f-feature="gf feature"
alias f-start="gf feature start"
alias f-publish="gf feature publish"
alias f-pull="gf feature pull origin"
alias f-finish="gf feature finish"
# gitflow release
alias f-release="gf release"
alias r-publish="gf release publish"
alias r-finish="gf release finish"

# Process status
alias psa="ps aux"
alias ht="htop"

# Easy folder and file loading
alias sites="~/Sites"
alias clients="~/Sites/clients"
alias projects="~/Sites/projects"
alias dl="~/Downloads"
alias dt="cd ~/Desktop"
alias apps="/Applications"
alias fl="~/dotfiles"

alias zload="source ~/.zshrc"
alias finder='open . -a finder.app'
alias browser="open -a Google\ Chrome $1"
alias canary="open -a Google\ Chrome\ Canary $1"

# Miscellaneous
alias cleanup="sudo find . -name '*.DS_Store' -type f -delete"
alias kll="killall"
alias h="history"
alias q="exit"

# Show the external IP
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# Check web page download time
alias curl:t='curl -s -w "%{time_total} seconds\n" -o /dev/null'

# alias chucknorris="sudo"
alias aliases="print -rl -- ${(k)aliases}"
alias functions="print -rl -- ${(k)functions}"
alias parameters="print -rl -- ${(k)parameters}"

# alias for editors
alias s="subl"
alias c="code"
alias c.="code ."

# android
alias android-emulator="$HOME/Library/Android/sdk/tools/emulator"
alias ae="android-emulator"

# docker
alias d="docker"
alias di="docker images"
alias dip="docker ps -q | xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}' | sed 's/ \// /'"
# alias da="docker attach $(docker-compose ps -q $1)"

# docker-compose
alias dc="docker-compose"
alias dcu="docker-compose up -d"
alias dcub="docker-compose up -d --build"
alias dcd="docker-compose down"
alias dcps="docker-compose ps"
alias dce="docker-compose exec"

# PHP
alias phps="php -S localhost:8181"
alias phpst="phps -t ./"

# npm
alias npmp="npm publish"
alias npma="npm adduser"
alias npmi="pnpm install --no-lock"
alias npml="npm list --depth=0"
alias npmu="npm uninstall"
alias npmig="npm install -g"
alias npmlg="npm list -g --depth=0"
alias npmug="npm uninstall -g"
alias npmlink="npm link"
alias npmurl="npm-url"
alias t="npm test"

# yarn
alias y="yarn"
alias yi="yarn install"
alias ys="yarn start"
alias yd="yarn dev"
alias yp="yarn prod"
alias yb="yarn build"
alias yw="yarn watch"
alias yl="yarn lint"
alias yt="yarn test"
alias ysb="yarn storybook"
alias yu="yarn upgrade-interactive --latest"

# vue
alias v="vue"
alias vui="vue ui"
alias vc="vue create"

# rails
alias r="bin/rails"
alias rs="bin/rails server"

# be nice
alias please=sudo

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
	colorflag="--color"
	export LS_COLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
else # macOS `ls`
	colorflag="-G"
	export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
fi

# Always use color output for `ls`
alias ls="command ls ${colorflag}"

# List all files colorized in long format
alias l="ls -lh ${colorflag}"

# List all files colorized in long format, including dot files
alias la="ls -lah ${colorflag}"

# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# `cat` with beautiful colors. requires Pygments installed.
# sudo easy_install Pygments
# alias cat='pygmentize -O style=monokai -f console256 -g'
alias cat="bat"

# IP addresses
alias ip="digshort myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | perl -nle'/(\d+\.\d+\.\d+\.\d+)/ && print $1'"

# Enhanced WHOIS lookups
alias whois="whois -h whois-servers.net"

alias ping="prettyping --nolegend"

# alias ht="htop"

# VIM
alias v="vim"
alias sv="sudo vim"

# File size
alias fs="stat -f \"%z bytes\""

# Control the system
alias restart='sudo shutdown -r now'
alias shutdown='sudo shutdown now'

# # tempo
# alias tempo='curl --silent "http://wttr.in/curitiba"'

# calendario
year=`date +'%Y'`
alias calendario="cal $year"

# mes
alias mes='cal'

# ssh add id_sra and ssh keyscan for bitbucket
alias ssid='ssh-add ~/.ssh/id_rsa && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts'
# ssid command and deploy with capstrano command
alias sdeploy='ssid && cap staging deploy'
alias pdeploy='ssid && cap production deploy'