# shellcheck shell=bash
# shellcheck disable=SC1090 # sources generated init scripts
# Tool integrations shared by bash and zsh. Sourced from bash/plugins.bash and
# zsh/plugins_after.zsh (before the zsh widget-wrapping plugins).

if [ -n "${ZSH_VERSION:-}" ]; then _dot_sh=zsh; else _dot_sh=bash; fi

# Path of command $1 in $_dot_w, without forking.
_dot_which() {
    _dot_w=
    if [ -n "${ZSH_VERSION:-}" ]; then
        _dot_w=${commands[$1]-}
    else
        hash "$1" 2>/dev/null && _dot_w=${BASH_CMDS[$1]-}
    fi
    [ -n "$_dot_w" ]
}

# Init scripts (`zoxide init` etc.) cost a fork each per shell start. Cache
# the output; regenerate when DEP (the binary or theme file) is newer.
# Usage: _dot_cache NAME DEP CMD... && . "$_dot_f"   (sourced at top level,
# since zsh makes `typeset` inside a function local)
# Clear with: rm -rf ~/.cache/shell
_dot_cache() {
    _dot_f="${XDG_CACHE_HOME:-$HOME/.cache}/shell/$1.$_dot_sh"
    if [ ! -s "$_dot_f" ] || [ "$2" -nt "$_dot_f" ]; then
        shift 2
        mkdir -p "${_dot_f%/*}" &&
            "$@" >"$_dot_f" 2>/dev/null && [ -s "$_dot_f" ] ||
            { rm -f "$_dot_f"; return 1; }
    fi
}

# dircolors (the solarized theme is a submodule; skip if it isn't checked out)
_dot_dc="$HOME/.config/shell/plugins/dircolors-solarized/dircolors.256dark"
if [ -f "$_dot_dc" ] && _dot_which dircolors && dot_256; then
    # -b: SHELL may be unset (env -i, some systemd units)
    _dot_cache dircolors "$_dot_dc" dircolors -b "$_dot_dc" && . "$_dot_f"
fi
unset _dot_dc

# zoxide
if _dot_which zoxide; then
    _dot_cache zoxide "$_dot_w" zoxide init "$_dot_sh" && . "$_dot_f"
fi

# fzf (Ctrl+T: fuzzy file insert, Alt+C: fuzzy cd). fzf >= 0.48 prints its
# shell integration itself; older Debian packages ship it under /usr/share/doc.
if _dot_which fzf; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    fi
    if _dot_cache fzf "$_dot_w" fzf --"$_dot_sh"; then
        . "$_dot_f"
    elif [ -f "/usr/share/doc/fzf/examples/key-bindings.$_dot_sh" ]; then
        # shellcheck source=/dev/null
        . "/usr/share/doc/fzf/examples/key-bindings.$_dot_sh"
    fi
fi

# direnv
if _dot_which direnv; then
    _dot_cache direnv "$_dot_w" direnv hook "$_dot_sh" && . "$_dot_f"
fi

# atuin, after fzf so its Ctrl+R binding wins
if _dot_which atuin; then
    _dot_cache atuin "$_dot_w" atuin init "$_dot_sh" && . "$_dot_f"
fi

# conda: defined lazily (first `conda ...` runs the hook)
source "$HOME/.config/shell/conda.sh"

unset _dot_sh _dot_w _dot_f
unset -f _dot_which _dot_cache
