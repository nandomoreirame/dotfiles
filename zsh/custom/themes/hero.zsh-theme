local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

local user_host='%{$terminfo[bold]$fg[blue]%}@%m%{$reset_color%}'
local git_branch='$(git_prompt_info)%{$reset_color%}'
local current_dir='${PWD/#$HOME/~}'
local user_symbol=' › '
local node_version=''

node_version='%{$fg[red]%}(node $(node -v) › npm $(npm -v))%{$reset_color%}'

PROMPT="${user_host} ${rvm_ruby} ${node_version} ${git_branch}
${current_dir}%B${user_symbol}%b"
RPS1="%B${return_code}%b"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="] %{$reset_color%}"