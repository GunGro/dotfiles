# Profile startup with `zbench -p` (see zsh/settings.zsh)
[[ -n $ZDOT_PROF ]] && zmodload zsh/zprof

# Machine-local switches (DOTFILES_GAMEDEV, DOTFILES_PERSONAL, ...), read first
if [ -f "$HOME/.config/shell/local_env.sh" ]; then
    source "$HOME/.config/shell/local_env.sh"
fi

# External plugins initialized before compinit
source "$HOME/.config/zsh/plugins_before.zsh"

# Settings
source "$HOME/.config/zsh/settings.zsh"

# Shared functions (path_prepend etc.)
source "$HOME/.config/shell/functions.sh"

# User-local tools go on PATH before anything probes with `command -v`
# (eza/btop aliases, zoxide, direnv, atuin), so a fresh login shell sees them.
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.atuin/bin"
path_prepend "$HOME/.local/bin"

# Shared aliases
source "$HOME/.config/shell/aliases.sh"

# Local aliases
if [ -f "$HOME/.config/shell/local_aliases.sh" ]; then
    source "$HOME/.config/shell/local_aliases.sh"
fi

if [ -f "$HOME/.config/zsh/local_aliases.zsh" ]; then
    source "$HOME/.config/zsh/local_aliases.zsh"
fi

# Local functions
if [ -f "$HOME/.config/shell/local_functions.sh" ]; then
    source "$HOME/.config/shell/local_functions.sh"
fi

if [ -f "$HOME/.config/zsh/local_functions.zsh" ]; then
    source "$HOME/.config/zsh/local_functions.zsh"
fi

# Machine-local extras: every *.sh in shell/local.d/ (not tracked by git)
for f in "$HOME"/.config/shell/local.d/*.sh(N); do
    # shellcheck source=/dev/null
    [ -f "$f" ] && source "$f"
done
unset f

# Custom prompt
source "$HOME/.config/zsh/prompt.zsh"

# External plugins initialized after compinit
source "$HOME/.config/zsh/plugins_after.zsh"

# Local changes
if [ -f "$HOME/.config/shell/local_changes.sh" ]; then
    source "$HOME/.config/shell/local_changes.sh"
fi

if [ -f "$HOME/.config/zsh/local_changes.zsh" ]; then
    source "$HOME/.config/zsh/local_changes.zsh"
fi

[[ -n $ZDOT_PROF ]] && zprof
