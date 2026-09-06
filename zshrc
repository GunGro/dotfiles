# External plugins initialized before compinit
source "$HOME/.config/zsh/plugins_before.zsh"

# Settings
source "$HOME/.config/zsh/settings.zsh"

# Shared aliases/functions
source "$HOME/.config/shell/aliases.sh"
source "$HOME/.config/shell/functions.sh"

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

# Custom prompt
source "$HOME/.config/zsh/prompt.zsh"

# External plugins initialized after compinit
source "$HOME/.config/zsh/plugins_after.zsh"

# atuin (loaded after fzf so its Ctrl+R binding takes precedence)
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

# Local changes
if [ -f "$HOME/.config/shell/local_changes.sh" ]; then
    source "$HOME/.config/shell/local_changes.sh"
fi

if [ -f "$HOME/.config/zsh/local_changes.zsh" ]; then
    source "$HOME/.config/zsh/local_changes.zsh"
fi

# User-local tools
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.local/bin"

if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi
