# External plugins (initialized before)

# zsh-completions
fpath=(~/.config/zsh/plugins/zsh-completions/src $fpath)

# conda completions
fpath+=~/.zsh/plugins/conda-zsh-completion
compinit conda
