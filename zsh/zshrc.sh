# First, load bash files.
. ~/.bashrc

export DOTFILES="$HOME/.dotfiles"
# export SPACESHIP_ROOT="$DOTFILES/zsh/custom/themes/spaceship-prompt"

source $HOME/.profile
source $HOME/.bash_profile

# Path to your oh-my-zsh installation
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$ZSH/custom
export ZSH_PLUGINS=$ZSH_CUSTOM/plugins

SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  # host          # Hostname section
  git           # Git section (git_branch + git_status)
  node          # Node.js section
  ruby          # Ruby section
  php           # PHP section
  # pyenv         # Pyenv section
  exec_time     # Execution time
  battery       # Line break
  line_sep      # Line break
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
SPACESHIP_USER_SHOW=always
SPACESHIP_HOST_SHOW=false
SPACESHIP_BATTERY_THRESHOLD=90
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "
# Prevent "Insecure completion-dependent directories detected" warning
# https://github.com/robbyrussell/oh-my-zsh/issues/6835#issuecomment-390216875
ZSH_DISABLE_COMPFIX=true

# Load ZSH
source $ZSH/oh-my-zsh.sh
source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH_PLUGINS/git-semantic-commits/git-semantic-commits.plugin.zsh

export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/opt/gettext/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/Library/Python/2.7/bin:$PATH"

export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# MySQL
# export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
export PATH="/usr/local/mysql/bin:$PATH"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

export PATH="$HOME/.composer/vendor/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="/usr/local/opt/tcl-tk/bin:$PATH"

# export JAVA_HOME=$(/usr/libexec/java_home)
# export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
# export PATH="$JAVA_HOME/bin:$PATH"

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

export PATH="/usr/local/opt/openldap/bin:$PATH"
export PATH="/usr/local/opt/openldap/sbin:$PATH"
export PATH="/usr/local/Cellar/php/7.2.11/bin/php:$PATH"

# PHP Composer
export PATH="$PATH:$HOME/.composer/vendor/bin"

# PHP Env - https://github.com/phpenv/phpenv
# export PATH="$HOME/.phpenv/bin:$PATH"
# eval "$(phpenv init -)"
# source $HOME/.phpbrew/bashrc
# export PHPBREW_SET_PROMPT=1
# export PHPBREW_RC_ENABLE=1

# rvm
# export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
# source $HOME/.rvm/scripts/rvm # Source rvm scripts

export PATH="$HOME/bin:$PATH";
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

export GPG_TTY=$(tty)

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

fpath=("$HOME/.zfunctions" $fpath)
fpath=("/usr/local/share/zsh-completions" $fpath)

# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc


# pnpm
export PNPM_HOME="/Users/nandomoreira/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# need cowsay # npm i -g cowsay
# cowsay -f "$DOTFILES/cowsay/bot.cow" $(vovo-juju) # and vovo-juju-cli # npm i -g vovo-juju-cli
# cowsay "DON'T DEPLOY ON FRIDAY!"

# Set Spaceship ZSH as a prompt
autoload -U promptinit; promptinit
prompt spaceship
