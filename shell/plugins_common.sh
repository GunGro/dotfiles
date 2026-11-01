# shellcheck shell=bash
# Tool integrations shared by bash and zsh. Sourced from bash/plugins.bash and
# zsh/plugins_after.zsh (before the zsh widget-wrapping plugins).

if [ -n "${ZSH_VERSION:-}" ]; then _dot_sh=zsh; else _dot_sh=bash; fi

# dircolors (the solarized theme is a submodule; skip if it isn't checked out)
_dot_dc="$HOME/.config/shell/plugins/dircolors-solarized/dircolors.256dark"
if [ -f "$_dot_dc" ] && command -v dircolors >/dev/null 2>&1 && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
    eval "$(dircolors -b "$_dot_dc")" # -b: SHELL may be unset (env -i, some systemd units)
fi
unset _dot_dc

# zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init "$_dot_sh")"
fi

# fzf (Ctrl+T: fuzzy file insert, Alt+C: fuzzy cd). fzf >= 0.48 prints its
# shell integration itself; older Debian packages ship it under /usr/share/doc.
if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    fi
    if _dot_fzf="$(fzf --"$_dot_sh" 2>/dev/null)" && [ -n "$_dot_fzf" ]; then
        eval "$_dot_fzf"
    elif [ -f "/usr/share/doc/fzf/examples/key-bindings.$_dot_sh" ]; then
        # shellcheck source=/dev/null
        . "/usr/share/doc/fzf/examples/key-bindings.$_dot_sh"
    fi
    unset _dot_fzf
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook "$_dot_sh")"
fi

# atuin, after fzf so its Ctrl+R binding wins
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init "$_dot_sh")"
fi

# conda: defined lazily (first `conda ...` runs the hook)
source "$HOME/.config/shell/conda.sh"

unset _dot_sh
