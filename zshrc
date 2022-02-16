# External plugins (initialized before)
source ~/.zsh/plugins_before.zsh

# Settings
source ~/.zsh/settings.zsh

# Aliases for all shells
source ~/.shell/aliases.sh

# Functions for all shells
source ~/.shell/functions.sh

# local aliases
if [ -f "$HOME/.shell/local_aliases.zsh" ]; then
    source ~/.shell/local_aliases.zsh
fi

if [ -f "$HOME/.zsh/local_aliases.zsh" ]; then
    source ~/.zsh/local_aliases.zsh
fi


# External zsh settings like conda 
if [ -f "$HOME/.zsh/external.zsh" ]; then
    source ~/.zsh/external.zsh
fi

# Custom prompt 
source ~/.zsh/prompt.zsh

# External plugins (initialized after)
source ~/.zsh/plugins_after.zsh

# local changes
if [ -f "$HOME/.zsh/local_changes.zsh" ]; then
    source ~/.zsh/local_changes.zsh
fi

