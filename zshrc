# External plugins (initialized before)
source ~/.config/zsh/plugins_before.zsh

# Settings
source ~/.config/zsh/settings.zsh

# Aliases for all shells
source ~/.config/shell/aliases.sh

# Functions for all shells
source ~/.config/shell/functions.sh

# local aliases
if [ -f "$HOME/.config/shell/local_aliases.sh" ]; then
    source ~/.shell/local_aliases.sh
fi

if [ -f "$HOME/.config/zsh/local_aliases.zsh" ]; then
    source ~/.config/zsh/local_aliases.zsh
fi

if [ -f "$HOME/.config/shell/local_functions.sh" ]; then
    source ~/.config/shell/local_functions.sh
fi

if [ -f "$HOME/.config/zsh/local_functions.zsh" ]; then
    source ~/.config/zsh/local_functions.zsh
fi

# Custom prompt 
source ~/.config/zsh/prompt.zsh

# External plugins (initialized after)
source ~/.config/zsh/plugins_after.zsh

# local changes
if [ -f "$HOME/.config/shell/local_changes.sh" ]; then
    source ~/.config/shell/local_changes.sh
fi

if [ -f "$HOME/.config/zsh/local_changes.zsh" ]; then
    source ~/.config/zsh/local_changes.zsh
fi

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
