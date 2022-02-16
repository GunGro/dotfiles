# ~/.bashrc: executed by bash(1) for non-login shells.
# External plugins (initialized before)

# Settings
source ~/.bash/settings.bash

# Aliases for all shells
source ~/.shell/aliases.sh

# Functions for all shells
source ~/.shell/functions.sh

# local aliases
if [ -f "$HOME/.shell/local_aliases.sh" ]; then
    source ~/.shell/local_aliases.sh
fi

if [ -f "$HOME/.bash/local_aliases.bash" ]; then
    source ~/.bash/local_aliases.bash
fi

if [ -f "$HOME/.shell/local_functions.sh" ]; then
    source ~/.shell/local_functions.sh
fi

if [ -f "$HOME/.bash/local_functions.bash" ]; then
    source ~/.bash/local_functions.bash

# Custom prompt 
source ~/.bash/prompt.bash

# External plugins (initialized after)
source ~/.bash/plugins.bash

# local changes
if [ -f "$HOME/.shell/local_changes.sh" ]; then
    source ~/.shell/local_changes.sh
fi

if [ -f "$HOME/.bash/local_changes.bash" ]; then
    source ~/.bash/local_changes.bash
fi

