# Completion
zstyle ':completion:*' menu select=4
zmodload zsh/complist 2>/dev/null || true
autoload -Uz compinit
# Full compinit (security audit + dump rebuild) at most once a day, cached
# (-C) otherwise. After adding completions, run `compreset`.
() {
    local dump="${ZDOTDIR:-$HOME}/.zcompdump"
    local -a stale=($dump(N.mh+24))
    if [[ ! -s $dump || ${#stale} -gt 0 ]]; then
        compinit -i -d "$dump"
    else
        compinit -C -d "$dump"
    fi
}
compreset() { rm -f "${ZDOTDIR:-$HOME}"/.zcompdump*(N) && exec zsh; }

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
setopt extended_history     # timestamps + durations
setopt inc_append_history  # write each command immediately (implies append)
setopt hist_ignore_dups    # no consecutive duplicates
setopt hist_ignore_space   # " cmd" stays out of history (secrets on the command line)
setopt hist_reduce_blanks
setopt hist_verify         # !! / !$ expand into the buffer instead of running
# Up-arrow stays per-session on purpose; atuin (Ctrl+R) searches all sessions.

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

# Startup time. zbench [N]: mean wall time of N `zsh -i -c exit` (default 10).
# zbench -p: zprof breakdown of one startup.
zbench() {
    if [[ $1 == -p ]]; then
        ZDOT_PROF=1 zsh -i -c exit
        return
    fi
    zmodload zsh/datetime
    local n=${1:-10} i t0=$EPOCHREALTIME
    for (( i = 0; i < n; i++ )); do zsh -i -c exit; done
    printf '%.1f ms\n' $(( (EPOCHREALTIME - t0) * 1000.0 / n ))
}
