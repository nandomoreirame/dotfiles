# Oh My Zsh options. Third-party plugins (autosuggestions, syntax-highlighting)
# and powerlevel10k load from Arch packages in .zshrc, not from this directory.

# Theme is sourced from the system package after omz loads.
ZSH_THEME=""

# Uncomment the following line to use case-sensitive completion
CASE_SENSITIVE="true"

# How often to auto-update (in days)
export UPDATE_ZSH_DAYS=99999

# Uncomment the following line to disable auto-setting terminal title
DISABLE_AUTO_TITLE="true"

# Enable command auto-correction
ENABLE_CORRECTION="false"

# Display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# Disable marking untracked files
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Change the command execution time stamp shown in the history command output
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd/mm/yyyy"

# Built-in oh-my-zsh plugins only (no vendored third-party plugins)
plugins=(
    colored-man-pages
    git
    extract
)

# User configuration
export EDITOR=vim
