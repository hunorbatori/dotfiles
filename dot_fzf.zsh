# Setup fzf
# ---------
if [[ ! "$PATH" == */home/huntszy/.zsh/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/huntszy/.zsh/fzf/bin"
fi

source <(fzf --zsh)
