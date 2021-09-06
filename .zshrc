# External plugins (initialized before)
source ~/.zsh/plugins_before.zsh

# Settings
source ~/.zsh/settings.zsh

# Aliases
source ~/.zsh/aliases.zsh

# External settings 
source ~/.zsh/external.zsh

# Custom prompt 
source ~/.zsh/prompt.zsh

# External plugins (initialized after)
source ~/.zsh/plugins_after.zsh

# local changes
if [ -f "$HOME/.zsh/local_changes.zsh" ]; then
    source ~/.zsh/local_changes.zsh
fi

