# Generic shell helpers, one module per topic under functions/.
# Author AI wrappers (claude/codex/commit with permissions disabled) and
# chrome-insecure live in private/shell/, not here.

source "$DOTFILES/lib/functions.sh"

_ZSH_FN_DIR="$DOTFILES/.oh-my-zsh/custom/functions"
for _zsh_fn_mod in spinner git navigation http download gcp; do
  source "$_ZSH_FN_DIR/${_zsh_fn_mod}.zsh"
done
unset _zsh_fn_mod _ZSH_FN_DIR
