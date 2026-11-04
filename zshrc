# Profile startup with `zbench -p` (see zsh/settings.zsh)
[[ -n $ZDOT_PROF ]] && zmodload zsh/zprof

# Machine-local switches (DOTFILES_GAMEDEV, DOTFILES_PERSONAL, ...), read first
if [ -f "$HOME/.config/shell/local_env.sh" ]; then
    source "$HOME/.config/shell/local_env.sh"
fi

# External plugins initialized before compinit
source "$HOME/.config/zsh/plugins_before.zsh"

# Settings
source "$HOME/.config/zsh/settings.zsh"

# PATH, EDITOR and path_prepend etc. Already read via ~/.zshenv; again here
# (idempotent) so the PATH order holds even if /etc/zsh/zprofile reset it.
source "$HOME/.config/shell/env.sh"

# Shared aliases
source "$HOME/.config/shell/aliases.sh"

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

# Machine-local extras: every *.sh in shell/local.d/ (not tracked by git)
for f in "$HOME"/.config/shell/local.d/*.sh(N); do
    # shellcheck source=/dev/null
    [ -f "$f" ] && source "$f"
done
unset f

# Custom prompt
source "$HOME/.config/zsh/prompt.zsh"

# External plugins initialized after compinit
source "$HOME/.config/zsh/plugins_after.zsh"

# Local changes
if [ -f "$HOME/.config/shell/local_changes.sh" ]; then
    source "$HOME/.config/shell/local_changes.sh"
fi

if [ -f "$HOME/.config/zsh/local_changes.zsh" ]; then
    source "$HOME/.config/zsh/local_changes.zsh"
fi

if [[ -n $ZDOT_PROF ]]; then zprof; fi

# The first prompt shows the exit status of the last command run here (the
# old `[[ -n $ZDOT_PROF ]] && zprof` left 1, hence a red `!` in every new
# shell). End on success whatever the local files above returned.
true
