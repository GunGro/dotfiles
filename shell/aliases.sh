# shellcheck shell=bash
# Sourced by bashrc and zshrc (not executed), so no shebang.
# Editor

alias vim='nvim'
alias vi='nvim'
alias v='nvim'

# Listing (eza if available, plain ls fallback)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first --git'
    alias la='eza -a --group-directories-first'
    alias l='eza -F --group-directories-first'
    alias lt='eza --tree --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi
alias grep='grep --color=auto'

# btop
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
fi

# Navigation

alias ..='cd ..'
alias ...='cd ../..'

# clear
alias c='clear'
# git
alias gag='git exec rg' # search from the repo root (ag is not installed; rg is)
alias lg='lazygit'


# git root
alias cdgr='cd "$(git root)"'

# ssh
alias sshx="ssh -X"

# AI shortcuts
alias ai='aichat'
alias aicode='aichat --role code' # terse code-focused answers

# Quick review: pipe a file to AI
# Usage: aireview sim.cpp
aireview() {
    cat "$1" | aichat "Review this code for correctness, style, and numerical stability. Be concise."
}

# Explain last command's output
# Usage: run a command, then: aiexplain
aiexplain() {
    aichat "Explain this terminal output and suggest fixes if needed:" </dev/stdin
}

# Optional parts, switched on in shell/local_env.sh (see local_env.sh.example).
# C/C++ helpers (CMake env, sanitizer builds, profiling, cores, netem, cxdet).
if { [ "${DOTFILES_CPP:-0}" = 1 ] || [ "${DOTFILES_GAMEDEV:-0}" = 1 ]; } && [ -f "$HOME/.config/shell/cpp.sh" ]; then
    . "$HOME/.config/shell/cpp.sh"
fi
# Godot / GDExtension helpers on top of cpp.sh.
if [ "${DOTFILES_GAMEDEV:-0}" = 1 ] && [ -f "$HOME/.config/shell/gamedev.sh" ]; then
    . "$HOME/.config/shell/gamedev.sh"
fi
# Personal one-letter shortcuts that are easy to trigger by accident.
if [ "${DOTFILES_PERSONAL:-0}" = 1 ] && [ -f "$HOME/.config/shell/personal.sh" ]; then
    . "$HOME/.config/shell/personal.sh"
fi
