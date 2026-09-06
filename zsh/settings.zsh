# Completion
zstyle ':completion:*' menu select=4
zmodload zsh/complist 2>/dev/null || true
autoload -Uz compinit
compinit -i

# Vim-style navigation keys in menu completion
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Edit command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line

setopt interactivecomments

# History
HISTSIZE=1000000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt incappendhistory
setopt extendedhistory

# Time to wait for additional characters in an escape sequence.
# Zsh uses hundredths of a second; 1 = 10 ms.
KEYTIMEOUT=1

# Editor
export EDITOR=nvim
export VISUAL=nvim

# Vim-style line editing
bindkey -v

disable r 2>/dev/null || true
unsetopt BEEP
