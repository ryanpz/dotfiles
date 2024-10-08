export VISUAL='nvim'
export EDITOR="$VISUAL"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GOPATH="$XDG_DATA_HOME/go"
export HISTFILE="$XDG_STATE_HOME/bash/history"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

PATH="$HOME/.local/bin:$CARGO_HOME/bin:$GOPATH/bin:/usr/local/go/bin:$XDG_DATA_HOME/npm/bin:$XDG_DATA_HOME/flatpak/exports/bin:$PATH"

[ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
