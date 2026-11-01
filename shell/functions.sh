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
