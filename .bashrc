[ -z "$PS1" ] && return

alias dot='git --git-dir="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles" --work-tree="$HOME"'
alias f='cd $(fproj)'
alias ls='ls --color=auto'
alias vi='nvim'

PS1='\[\033[01m\]\W \$\[\033[00m\] '

[ -f "$HOME"/.bashrc.local ] && . "$HOME"/.bashrc.local

print_friend
