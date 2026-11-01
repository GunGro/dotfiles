# shellcheck shell=bash
# Environment for every shell, interactive or not: sourced by ~/.zshenv and by
# bashrc before its interactive-only guard. So `ssh host uv run ...` or
# `ssh host nvim` finds user-local tools without a login shell. Keep it quiet
# and fork-free: it also runs for scripts and scp/rsync sessions.

. "$HOME/.config/shell/functions.sh"

# User-local tools go first, before anything probes with `command -v`
# (eza/btop aliases, zoxide, direnv, atuin).
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.atuin/bin"
path_prepend "$HOME/.local/bin"

export EDITOR=nvim
export VISUAL=nvim
