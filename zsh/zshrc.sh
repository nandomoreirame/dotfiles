# First, load bash files.
. ~/.bashrc

source $HOME/.profile
source $HOME/.bash_profile

fpath=("$HOME/.zfunctions" $fpath)

# Path to your oh-my-zsh installation
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$ZSH/custom
export ZSH_PLUGINS=$ZSH_CUSTOM/plugins

# Prevent "Insecure completion-dependent directories detected" warning
# https://github.com/robbyrussell/oh-my-zsh/issues/6835#issuecomment-390216875
ZSH_DISABLE_COMPFIX=true

# Load ZSH
source $ZSH/oh-my-zsh.sh
source $ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="/usr/local/opt/gettext/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/Library/Python/2.7/bin:$PATH"

export PATH="/usr/local/opt/openssl/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

# export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
# export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
# export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
# export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

export PATH="$HOME/.composer/vendor/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

export ANDROID_HOME="$HOME/Library/Android/sdk"
# export PATH="${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:$PATH"
path=("${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools" $path)

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

export PATH="/usr/local/opt/openldap/bin:$PATH"
export PATH="/usr/local/opt/openldap/sbin:$PATH"
export PATH="/usr/local/Cellar/php/7.2.11/bin/php:$PATH"

# export rvm
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
# Source rvm scripts
source $HOME/.rvm/scripts/rvm

# Adding autocomplete for 'we'
[ -f ~/.we_autocomplete ] && source ~/.we_autocomplete

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

# Set Spaceship ZSH as a prompt
autoload -U promptinit; promptinit
prompt spaceship

# vovo-juju # need `npm i -g vovo-juju-cli`
cowsay "Good luck dev!" # need `npm i -g cowsay`