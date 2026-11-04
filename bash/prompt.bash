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

# Git status after the directory, with the zsh RPROMPT's symbols and colours:
#   (+ahead -behind x=merging, - untracked/modified/staged)(branch, ! = detached)
# One `git status --porcelain=v2 --branch` per prompt (plus rev-parse, and
# name-rev only on a detached HEAD). Bash has no async prompt, so in a huge
# repo turn it off with PR_SHOW_GIT=false.
PR_SHOW_GIT=${PR_SHOW_GIT:-true}
if dot_256; then
    printf -v __pr_cv '\001\e[38;5;%sm\002' 61  # violet
    printf -v __pr_ct '\001\e[38;5;%sm\002' 41  # teal
    printf -v __pr_co '\001\e[38;5;%sm\002' 166 # orange
    printf -v __pr_cc '\001\e[38;5;%sm\002' 37  # cyan
    printf -v __pr_cr '\001\e[38;5;%sm\002' 160 # red
    printf -v __pr_cy '\001\e[38;5;%sm\002' 136 # yellow
    printf -v __pr_cg '\001\e[38;5;%sm\002' 64  # green
    printf -v __pr_cm '\001\e[38;5;%sm\002' 125 # magenta
    printf -v __pr_cn '\001\e[38;5;%sm\002' 112 # neon
else
    __pr_cv=$'\001\e[35m\002' __pr_ct=$'\001\e[36m\002' __pr_co=$'\001\e[33m\002'
    __pr_cc=$'\001\e[36m\002' __pr_cr=$'\001\e[31m\002' __pr_cy=$'\001\e[33m\002'
    __pr_cg=$'\001\e[32m\002' __pr_cm=$'\001\e[35m\002' __pr_cn=$'\001\e[32m\002'
fi
__pr_b=$'\001\e[1m\002' __pr_r=$'\001\e[0m\002'

__pr_git_update() {
    __pr_git=
    [ "$PR_SHOW_GIT" = true ] || return 0
    local gitdir line head="" ahead=0 behind=0 staged=0 modified=0 untracked=0
    gitdir="$(git rev-parse --git-dir 2>/dev/null)" || return 0
    while IFS= read -r line; do
        case $line in
            '# branch.head '*) head=${line#'# branch.head '} ;;
            '# branch.ab '*)
                read -r ahead behind <<<"${line#'# branch.ab '}"
                ahead=${ahead#+} behind=${behind#-} ;;
            '#'*) ;;
            '? '*) untracked=1 ;;
            'u '*) modified=1 ;;
            [12]' '*)
                [ "${line:2:1}" != . ] && staged=1
                [ "${line:3:1}" != . ] && modified=1 ;;
        esac
    done < <(git status --porcelain=v2 --branch 2>/dev/null)

    local where detached=""
    if [ "$head" = '(detached)' ]; then
        where="$(git name-rev --name-only --no-undefined --always HEAD 2>/dev/null)"
        where=${where#tags/}
        detached="$__pr_cn$__pr_b!$__pr_r"
    else
        where=$head
    fi
    [ -n "$where" ] || return 0

    local state="" diff="" open="$__pr_cv$__pr_b($__pr_r" close="$__pr_cv$__pr_b)$__pr_r"
    [ "$ahead" -gt 0 ] && state="$__pr_ct$__pr_b+$ahead$__pr_r"
    [ "$behind" -gt 0 ] && state="${state:+$state }$__pr_co$__pr_b-$behind$__pr_r"
    [ -r "$gitdir/MERGE_HEAD" ] && state="${state:+$state }$__pr_cc${__pr_b}x$__pr_r"
    [ "$untracked" = 1 ] && diff="$__pr_cr$__pr_b-$__pr_r"
    [ "$modified" = 1 ] && diff="$diff$__pr_cy$__pr_b-$__pr_r"
    [ "$staged" = 1 ] && diff="$diff$__pr_cg$__pr_b-$__pr_r"
    [ -n "$state" ] && [ -n "$diff" ] && state="$state "
    state="$state$diff"
    [ -n "$state" ] && state="$open$state$close"
    __pr_git=" $state$open$__pr_cm$__pr_b$where$__pr_r$detached$close"
}

# __pr_capture first: it must see $? before anything else runs.
PROMPT_COMMAND="__pr_capture; __pr_git_update${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

PROMPT_DIRTRIM=3
PS1="${COLOR_BLUE}#${COLOR_DEFAULT} ${COLOR_CYAN}\\u${COLOR_DEFAULT} ${COLOR_GREEN}at${COLOR_DEFAULT} ${COLOR_MAGENTA}\${__pr_machine}${COLOR_DEFAULT} ${COLOR_GREEN}in${COLOR_DEFAULT} ${COLOR_YELLOW}\w${COLOR_DEFAULT}\${__pr_git}\n\${__pr_err}${COLOR_BLUE}>${COLOR_DEFAULT} "
PS2="${COLOR_BLUE}>${COLOR_DEFAULT} "

COLOR_GRAY='\e[38;5;246m'

demoprompt() {
    PROMPT_DIRTRIM=1
    PS1="${COLOR_GRAY}\w ${COLOR_BLUE}\$ "
    trap '[[ -t 1 ]] && tput sgr0' DEBUG
}
