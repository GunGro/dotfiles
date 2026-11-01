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
    # Load the dump as bytecode: compinit -C on the plain file is ~15 ms of
    # parsing, the .zwc loads in ~1 ms. Recompiled whenever the dump changes.
    if [[ -s $dump && ( ! -s $dump.zwc || $dump -nt $dump.zwc ) ]]; then
        zcompile "$dump" 2>/dev/null
    fi
}
compreset() { rm -f "${ZDOTDIR:-$HOME}"/.zcompdump*(N) && exec zsh; }

# Vim-style navigation keys in menu completion
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history


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

# Vim-style line editing
bindkey -v

# Edit the command line in $EDITOR: `v` in normal mode (as in bash's vi mode).
# The widget was defined before but never bound to a key.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Insert mode deletes like bash's vi mode (readline): Backspace, ^W and ^U go
# past the point where insert mode was entered. zsh's vi-* defaults stop there.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line

# Mode as cursor shape, as in bash (inputrc): beam in insert, block in normal,
# terminal default while a command runs. Hook widgets, so they compose with
# zsh-autosuggestions / zsh-syntax-highlighting.
autoload -Uz add-zle-hook-widget
_dot_vi_cursor() {
    if [[ $KEYMAP == vicmd ]]; then print -n '\e[2 q'; else print -n '\e[6 q'; fi
}
add-zle-hook-widget keymap-select _dot_vi_cursor
add-zle-hook-widget line-init _dot_vi_cursor
_dot_cursor_reset() { print -n '\e[0 q'; }
autoload -Uz add-zsh-hook
add-zsh-hook preexec _dot_cursor_reset

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
