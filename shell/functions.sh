#! /bin/env bash
path_remove() {
    local target="$1"
    local IFS=:
    local -a parts=($PATH)
    local -a kept=()
    local part
    for part in "${parts[@]}"; do
        [[ "$part" == "$target" ]] || kept+=("$part")
    done
    PATH="${kept[*]}"
    IFS=' '
}

path_append() {
    path_remove "$1"
    PATH="${PATH:+"$PATH:"}$1"
}

path_prepend() {
    path_remove "$1"
    PATH="$1${PATH:+":$PATH"}"
}
