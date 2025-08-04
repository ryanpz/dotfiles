[ -z "$PS1" ] && return

alias dot='git --git-dir="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles" --work-tree="$HOME"'
alias f='cd $(fproj)'
alias k='kubectl'
alias ls='ls --color=auto'
alias tn='tmux new -d -t "${PWD##*/}" && tmux new-window && tmux select-window -t :0 && tmux a'
alias vi='nvim'

bind -x '"\C-f":"fg"'

PS1='\[\033[01m\]\W \$\[\033[00m\] '

[ -f "$HOME"/.bashrc.local ]  && . "$HOME"/.bashrc.local

print_friend
