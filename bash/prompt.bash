ATTRIBUTE_BOLD='\[\e[1m\]'
ATTRIBUTE_RESET='\[\e[0m\]'
COLOR_DEFAULT='\[\e[39m\]'
COLOR_RED='\[\e[31m\]'
COLOR_GREEN='\[\e[32m\]'
COLOR_YELLOW='\[\e[33m\]'
COLOR_BLUE='\[\e[34m\]'
COLOR_MAGENTA='\[\e[35m\]'
COLOR_CYAN='\[\e[36m\]'

machine_name() {
    if [[ -f $HOME/.name ]]; then
        cat "$HOME/.name"
    else
        hostname
    fi
}
__pr_machine="$(machine_name)" # once per shell, not a fork per prompt

# Exit status of the last command, captured before anything else in
# PROMPT_COMMAND runs. The old `$(if [ $? -ne 0 ] ...)` inside PS1 never saw
# it: the earlier $(machine_name) substitution (and `history -a`) reset $?.
# With bash-preexec (atuin), its saved status is the authoritative one.
__pr_capture() {
    local s=$?
    s=${__bp_last_ret_value:-$s}
    if [ "$s" -ne 0 ]; then
        __pr_err=$'\001\e[31m\002!\001\e[39m\002 '
    else
        __pr_err=
    fi
}
PROMPT_COMMAND="__pr_capture${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

PROMPT_DIRTRIM=3
PS1="${COLOR_BLUE}#${COLOR_DEFAULT} ${COLOR_CYAN}\\u${COLOR_DEFAULT} ${COLOR_GREEN}at${COLOR_DEFAULT} ${COLOR_MAGENTA}\${__pr_machine}${COLOR_DEFAULT} ${COLOR_GREEN}in${COLOR_DEFAULT} ${COLOR_YELLOW}\w${COLOR_DEFAULT}\n\${__pr_err}${COLOR_BLUE}>${COLOR_DEFAULT} "
PS2="${COLOR_BLUE}>${COLOR_DEFAULT} "

COLOR_GRAY='\e[38;5;246m'

demoprompt() {
    PROMPT_DIRTRIM=1
    PS1="${COLOR_GRAY}\w ${COLOR_BLUE}\$ "
    trap '[[ -t 1 ]] && tput sgr0' DEBUG
}
