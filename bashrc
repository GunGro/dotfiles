# ~/.bashrc: executed by bash(1) for non-login shells.
# External plugins (initialized before)

# Settings
source ~/.config/bash/settings.bash

# Aliases for all shells
source ~/.config/shell/aliases.sh

# Functions for all shells
source ~/.config/shell/functions.sh

# local aliases
if [ -f "$HOME/.config/shell/local_aliases.sh" ]; then
    source ~/.config/shell/local_aliases.sh
fi

if [ -f "$HOME/.config/bash/local_aliases.bash" ]; then
    source ~/.config/bash/local_aliases.bash
fi

if [ -f "$HOME/.config/shell/local_functions.sh" ]; then
    source ~/.config/shell/local_functions.sh
fi

if [ -f "$HOME/.config/bash/local_functions.bash" ]; then
    source ~/.config/bash/local_functions.bash
fi

# Custom prompt
source ~/.config/bash/prompt.bash

# External plugins (initialized after)
source ~/.config/bash/plugins.bash

# local changes
if [ -f "$HOME/.config/shell/local_changes.sh" ]; then
    source ~/.config/shell/local_changes.sh
fi

if [ -f "$HOME/.config/bash/local_changes.bash" ]; then
    source ~/.config/bash/local_changes.bash
fi

. "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
