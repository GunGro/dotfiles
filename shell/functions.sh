# shellcheck shell=bash
# Sourced by bashrc and zshrc (not executed), so no shebang.
# Remove every occurrence of $1 from PATH. Splits by hand: the old
# `parts=($PATH)` never split in zsh (no SH_WORD_SPLIT), so path_prepend
# kept stacking duplicates there. Empty entries (= cwd) are dropped too.
path_remove() {
    local target="$1" kept="" part rest="$PATH:"
    while [ -n "$rest" ]; do
        part="${rest%%:*}"
        rest="${rest#*:}"
        [ -z "$part" ] || [ "$part" = "$target" ] || kept="${kept:+$kept:}$part"
    done
    PATH="$kept"
}

path_append() {
    path_remove "$1"
    PATH="${PATH:+"$PATH:"}$1"
}

path_prepend() {
    path_remove "$1"
    PATH="$1${PATH:+":$PATH"}"
}

# True if the terminal has >= 256 colours. Looked up once per shell; zsh reads
# terminfo in-process, bash forks tput once.
dot_256() {
    if [ -z "${_dot_colors:-}" ]; then
        if [ -n "${ZSH_VERSION:-}" ] && zmodload zsh/terminfo 2>/dev/null; then
            _dot_colors=${terminfo[colors]:-0}
        else
            _dot_colors=$(tput colors 2>/dev/null || echo 0)
        fi
    fi
    [ "$_dot_colors" -ge 256 ] 2>/dev/null
}
