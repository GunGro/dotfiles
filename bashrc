# ~/.bashrc: executed by bash(1) for non-login interactive shells.

case $- in
    *i*) ;;
    *) return ;;
esac

# Settings
source "$HOME/.config/bash/settings.bash"

# Shared aliases/functions
source "$HOME/.config/shell/aliases.sh"
source "$HOME/.config/shell/functions.sh"

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

# Custom prompt
source "$HOME/.config/bash/prompt.bash"

# External plugins
source "$HOME/.config/bash/plugins.bash"

# atuin (loaded after fzf so its Ctrl+R binding takes precedence)
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
fi

# Local changes
if [ -f "$HOME/.config/shell/local_changes.sh" ]; then
    source "$HOME/.config/shell/local_changes.sh"
fi

if [ -f "$HOME/.config/bash/local_changes.bash" ]; then
    source "$HOME/.config/bash/local_changes.bash"
fi

# User-local tools
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.local/bin"

if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi
