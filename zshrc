# External plugins (initialized before)
source ~/.zsh/plugins_before.zsh

# Settings
source ~/.zsh/settings.zsh

# Aliases for all shells
source ~/.shell/aliases.sh

# Functions for all shells
source ~/.shell/functions.sh

# local aliases
if [ -f "$HOME/.shell/local_aliases.sh" ]; then
    source ~/.shell/local_aliases.sh
fi

if [ -f "$HOME/.zsh/local_aliases.zsh" ]; then
    source ~/.zsh/local_aliases.zsh
fi

if [ -f "$HOME/.shell/local_functions.sh" ]; then
    source ~/.shell/local_functions.sh
fi

if [ -f "$HOME/.zsh/local_functions.zsh" ]; then
    source ~/.zsh/local_functions.zsh

# Custom prompt 
source ~/.zsh/prompt.zsh

# External plugins (initialized after)
source ~/.zsh/plugins_after.zsh

# local changes
if [ -f "$HOME/.shell/local_changes.sh" ]; then
    source ~/.shell/local_changes.sh
fi

if [ -f "$HOME/.zsh/local_changes.zsh" ]; then
    source ~/.zsh/local_changes.zsh
fi

