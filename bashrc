# ~/.bashrc: executed by bash(1) for non-login interactive shells, and by
# sshd's bash for `ssh host cmd`.

# PATH and EDITOR for every shell, so `ssh host cmd` finds ~/.local/bin tools.
if [ -f "$HOME/.config/shell/env.sh" ]; then
    source "$HOME/.config/shell/env.sh"
fi

case $- in
    *i*) ;;
    *) return ;;
esac

# Machine-local switches (DOTFILES_GAMEDEV, DOTFILES_PERSONAL, ...), read first
if [ -f "$HOME/.config/shell/local_env.sh" ]; then
    source "$HOME/.config/shell/local_env.sh"
fi

# Settings
source "$HOME/.config/bash/settings.bash"


# Shared aliases
source "$HOME/.config/shell/aliases.sh"

# Local aliases
if [ -f "$HOME/.config/shell/local_aliases.sh" ]; then
    source "$HOME/.config/shell/local_aliases.sh"
fi

if [ -f "$HOME/.config/bash/local_aliases.bash" ]; then
    source "$HOME/.config/bash/local_aliases.bash"
fi

# Local functions
if [ -f "$HOME/.config/shell/local_functions.sh" ]; then
    source "$HOME/.config/shell/local_functions.sh"
fi

if [ -f "$HOME/.config/bash/local_functions.bash" ]; then
    source "$HOME/.config/bash/local_functions.bash"
fi

# Machine-local extras: every *.sh in shell/local.d/ (not tracked by git)
for f in "$HOME"/.config/shell/local.d/*.sh; do
    # shellcheck source=/dev/null
    [ -f "$f" ] && source "$f"
done
unset f

# Custom prompt
source "$HOME/.config/bash/prompt.bash"

# External plugins
source "$HOME/.config/bash/plugins.bash"

# Local changes
if [ -f "$HOME/.config/shell/local_changes.sh" ]; then
    source "$HOME/.config/shell/local_changes.sh"
fi

if [ -f "$HOME/.config/bash/local_changes.bash" ]; then
    source "$HOME/.config/bash/local_changes.bash"
fi
