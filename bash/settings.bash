export HISTSIZE=1048576
export HISTFILESIZE=1048576
export HISTFILE="$HOME/.bash_history"
shopt -s histappend # append to history file
export HISTCONTROL=ignoreboth # skip duplicates and " cmd" (secrets on the command line)
export HISTTIMEFORMAT='%F %T '
# Write each command as it runs, so a crashed/killed shell loses nothing.
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

set -o vi

shopt -s checkwinsize # update LINES/COLUMNS after each command

# Programmable completion (Debian's default ~/.bashrc does this; ours replaces it)
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi
