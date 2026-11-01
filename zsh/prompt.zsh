# User customizable options
# PR_ARROW_CHAR="[some character]"
# RPR_SHOW_USER=(true, false) - show username in rhs prompt
# RPR_SHOW_HOST=(true, false) - show host in rhs prompt
# RPR_SHOW_GIT=(true, false) - show git status in rhs prompt
# PR_EXTRA="[stuff]" - extra content to add to prompt
# RPR_EXTRA="[stuff]" - extra content to add to rhs prompt

# Set custom prompt

# Allow for variable/function substitution in prompt
setopt prompt_subst

# Load color variables to make it easier to color things
autoload -U colors && colors

# Make using 256 colors easier
if command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
    source ~/.config/zsh/plugins/spectrum.zsh
    
    # change default colors
    fg[red]=$FG[160]
    fg[green]=$FG[064]
    fg[yellow]=$FG[136]
    fg[blue]=$FG[033]
    fg[magenta]=$FG[125]
    fg[cyan]=$FG[037]

    fg[teal]=$FG[041]
    fg[orange]=$FG[166]
    fg[violet]=$FG[061]
    fg[neon]=$FG[112]
    fg[pink]=$FG[183]
else
    fg[teal]=$fg[blue]
    fg[orange]=$fg[yellow]
    fg[violet]=$fg[magenta]
    fg[neon]=$fg[green]
    fg[pink]=$fg[magenta]
fi

# Current directory, truncated to 3 path elements (or 4 when one of them is "~")
# The number of elements to keep can be specified as ${1}
function PR_DIR() {
    local sub=${1}
    if [[ "${sub}" == "" ]]; then
        sub=3
    fi
    local len=$(( sub + 1 ))
    # ${(%):-...} prompt-expands in-process (print -P in $(...) forked 5x)
    local full=${(%):-%d}
    local relfull=${(%):-%~}
    local shorter=${(%):-%${len}~}
    local current=${(%):-%${len}(~:.../:)%${sub}~}
    local last=${(%):-%1~}

    # Longer path for '~/...'
    if [[ "${shorter}" == \~/* ]]; then
        current=${shorter}
    fi

    local truncated="${current%/*}/"

    # Handle special case of directory '/' or '~something'
    if [[ "${truncated}" == "/" || "${relfull[1,-2]}" != */* ]]; then
        truncated=""
    fi

    # Handle special case of last being '/...' one directory down
    if [[ "${full[2,-1]}" != "" && "${full[2,-1]}" != */* ]]; then
        truncated="/"
        last=${last[2,-1]} # take substring
    fi

    echo "%{$fg[green]%}${truncated}%{$fg[orange]%}%B${last}%b%{$reset_color%}"
}

# An exclamation point if the previous command did not complete successfully
function PR_ERROR() {
    echo "%(?..%(!.%{$fg[violet]%}.%{$fg[red]%})%B!%b%{$reset_color%} )"
}

# The arrow symbol that is used in the prompt
PR_ARROW_CHAR=">"

# The arrow in red (for root) or violet (for regular user)
function PR_ARROW() {
    echo "%(!.%{$fg[red]%}.%{$fg[violet]%})${PR_ARROW_CHAR}%{$reset_color%}"
}

# Set custom rhs prompt
# User in red (for root) or violet (for regular user)
RPR_SHOW_USER=true # Set to false to disable user in rhs prompt
function RPR_USER() {
    if [[ "${RPR_SHOW_USER}" == "true" ]]; then
        echo "%(!.%{$fg[red]%}.%{$fg[violet]%})%B%n%b%{$reset_color%}"
    fi
}

function machine_name() {
    if [[ -f $HOME/.name ]]; then
        print -r -- "$(<$HOME/.name)"
    else
        print -r -- "${HOST:-$(hostname)}"
    fi
}

# Host in a deterministically chosen color, computed once per shell.
# Same colour as the old per-prompt python: int(sha1, 16) % 5, and since
# 16 = 1 (mod 5) that equals the sum of the hex digits mod 5.
_pr_host_colors=(cyan green yellow red pink)
_pr_machine="$(machine_name)"
# The sha1sum fork costs ~4 ms per shell start, so the result is cached per
# machine name in ~/.cache/zsh.
() {
    local hex d sum=0 cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/host-color-${_pr_machine//\//_}"
    if [[ -r $cache ]]; then
        _pr_host_color=$(<$cache)
        (( ${_pr_host_colors[(Ie)$_pr_host_color]} )) && return
    fi
    hex=${${"$(print -rn -- "$_pr_machine" | sha1sum)"}[1,40]}
    for d in ${(s::)hex}; do (( sum += 16#$d )); done
    _pr_host_color=$_pr_host_colors[$(( sum % ${#_pr_host_colors} + 1 ))]
    mkdir -p "${cache:h}" 2>/dev/null && print -r -- "$_pr_host_color" >| "$cache" 2>/dev/null
}

RPR_SHOW_HOST=true # Set to false to disable host in rhs prompt
function RPR_HOST() {
    if [[ "${RPR_SHOW_HOST}" == "true" ]]; then
        echo "%{$fg[$_pr_host_color]%}${_pr_machine}%{$reset_color%}"
    fi
}

# ' at ' in orange outputted only if both user and host enabled
function RPR_AT() {
    if [[ "${RPR_SHOW_USER}" == "true" ]] && [[ "${RPR_SHOW_HOST}" == "true" ]]; then
        echo "%{$fg[blue]%} at %{$reset_color%}"
    fi
}

# Build the rhs prompt
function RPR_INFO() {
    echo "$(RPR_USER)$(RPR_AT)$(RPR_HOST)"
}

# Set RHS prompt for git repositories
DIFF_SYMBOL="-"
GIT_PROMPT_SYMBOL=""
GIT_PROMPT_PREFIX="%{$fg[violet]%}%B(%b%{$reset_color%}"
GIT_PROMPT_SUFFIX="%{$fg[violet]%}%B)%b%{$reset_color%}"
GIT_PROMPT_AHEAD="%{$fg[teal]%}%B+NUM%b%{$reset_color%}"
GIT_PROMPT_BEHIND="%{$fg[orange]%}%B-NUM%b%{$reset_color%}"
GIT_PROMPT_MERGING="%{$fg[cyan]%}%Bx%b%{$reset_color%}"
GIT_PROMPT_UNTRACKED="%{$fg[red]%}%B$DIFF_SYMBOL%b%{$reset_color%}"
GIT_PROMPT_MODIFIED="%{$fg[yellow]%}%B$DIFF_SYMBOL%b%{$reset_color%}"
GIT_PROMPT_STAGED="%{$fg[green]%}%B$DIFF_SYMBOL%b%{$reset_color%}"
GIT_PROMPT_DETACHED="%{$fg[neon]%}%B!%b%{$reset_color%}"

# Branch, ahead/behind, staged/modified/untracked from ONE `git status
# --porcelain=v2 --branch` (was ~7 git processes per prompt). Plus one
# rev-parse for the merge marker and name-rev only on a detached HEAD.
function git_prompt_string() {
    [[ "${RPR_SHOW_GIT}" == "true" ]] || return
    local gitdir
    gitdir="$(git rev-parse --git-dir 2>/dev/null)" || return

    local line head="" ahead=0 behind=0 staged=0 modified=0 untracked=0
    while IFS= read -r line; do
        case $line in
            '# branch.head '*) head=${line#\# branch.head } ;;
            '# branch.ab '*)
                local ab=(${=${line#\# branch.ab }})
                ahead=${ab[1]#+}; behind=${ab[2]#-} ;;
            '#'*) ;;
            '? '*) untracked=1 ;;
            'u '*) modified=1 ;;
            [12]' '*)
                [[ ${line[3]} != . ]] && staged=1
                [[ ${line[4]} != . ]] && modified=1 ;;
        esac
    done < <(git status --porcelain=v2 --branch 2>/dev/null)

    local where detached=""
    if [[ $head == '(detached)' ]]; then
        where="$(git name-rev --name-only --no-undefined --always HEAD 2>/dev/null)"
        where=${where#tags/}
        detached=$GIT_PROMPT_DETACHED
    else
        where=$head
    fi
    [[ -n $where ]] || return

    local state="" diff=""
    (( ahead > 0 )) && state=${GIT_PROMPT_AHEAD//NUM/$ahead}
    (( behind > 0 )) && state="${state:+$state }${GIT_PROMPT_BEHIND//NUM/$behind}"
    [[ -r "$gitdir/MERGE_HEAD" ]] && state="${state:+$state }$GIT_PROMPT_MERGING"
    (( untracked )) && diff=$GIT_PROMPT_UNTRACKED
    (( modified )) && diff=$diff$GIT_PROMPT_MODIFIED
    (( staged )) && diff=$diff$GIT_PROMPT_STAGED
    [[ -n $state && -n $diff ]] && state="$state "
    state="$state$diff"

    local st=""
    [[ -n $state ]] && st="$GIT_PROMPT_PREFIX$state$GIT_PROMPT_SUFFIX"
    echo " $GIT_PROMPT_SYMBOL$st$GIT_PROMPT_PREFIX%{$fg[magenta]%}%B${where}%b$detached$GIT_PROMPT_SUFFIX"
}
RPR_SHOW_GIT=true # Set to false to disable git status in rhs prompt

PROMPT_MODE=0
PROMPT_MODES=4

# Function to toggle between prompt modes
function tog() {
    PROMPT_MODE=$(( (PROMPT_MODE + 1) % PROMPT_MODES))
}

function PR_EXTRA() {
    # do nothing by default
}

# Show select exported environment variables

_pr_var_list=()
_vars_multiline=false

function vshow() {
    local v
    for v in "$@"; do
        if [[ "${v}" =~ '[A-Z_]+' ]]; then
            if [[ ${_pr_var_list[(i)${v}]} -gt ${#_pr_var_list} ]]; then
                _pr_var_list+=("${v}")
            fi
        fi
    done
}

function vhide() {
    local v
    for v in "$@"; do
        _pr_var_list[${_pr_var_list[(i)${v}]}]=()
    done
}

function vmultiline() {
    if $_vars_multiline; then
        _vars_multiline=false
    else
        _vars_multiline=true
    fi
}

function PR_VARS() {
    local i v spc nl
    if $_vars_multiline; then
        spc=""
        nl="\n"
    else
        spc=" "
        nl=""
    fi
    for ((i=1; i <= ${#_pr_var_list}; i++)) do
        local v=${_pr_var_list[i]}
        if [[ -v "${v}" ]]; then
            # if variable is set
            if [[ ${(Pt)v} == *export* ]]; then
                # if exported, show regularly
                printf '%s' "$spc%{$fg[cyan]%}${v}=${(P)${v}}%{$reset_color%}$nl"
            else
                # if not exported, show in red
                printf '%s' "$spc%{$fg[red]%}${v}=${(P)${v}}%{$reset_color%}$nl"
            fi
        fi
    done
    # show project-specific vars
    while read v; do
        if [[ "${v}" =~ '[A-Z_]+' ]]; then
            # valid environment variable
            if [[ ${_pr_var_list[(i)${v}]} -gt ${#_pr_var_list} ]]; then
                # not shown yet
                if [[ ${(Pt)v} == *export* ]]; then
                    # exported
                    printf '%s' "$spc%{$fg[cyan]%}${v}=${(P)${v}}%{$reset_color%}$nl"
                fi
            fi
        fi
    done < <([[ -n $_pr_gitroot && -r $_pr_gitroot/.showvars ]] && print -r -- "$(<$_pr_gitroot/.showvars)")
}

# Git root for .showvars, refreshed on cd instead of a git call per prompt.
autoload -Uz add-zsh-hook
function _pr_update_gitroot() { _pr_gitroot="$(git rev-parse --show-toplevel 2>/dev/null)"; }
add-zsh-hook chpwd _pr_update_gitroot
_pr_update_gitroot

# Prompt
function PCMD() {
    if (( PROMPT_MODE == 0 )); then
        if $_vars_multiline; then
            echo "$(PR_VARS)$(PR_EXTRA)$(PR_DIR) $(PR_ERROR)$(PR_ARROW) " # space at the end
        else
            echo "$(PR_EXTRA)$(PR_DIR)$(PR_VARS) $(PR_ERROR)$(PR_ARROW) " # space at the end
        fi
    elif (( PROMPT_MODE == 1 )); then
        echo "$(PR_EXTRA)$(PR_DIR 1) $(PR_ERROR)$(PR_ARROW) " # space at the end
    else
        echo "$(PR_EXTRA)$(PR_ERROR)$(PR_ARROW) " # space at the end
    fi
}

PROMPT='$(PCMD)' # single quotes to prevent immediate execution
RPROMPT='' # set asynchronously and dynamically

function RPR_EXTRA() {
    # do nothing by default
}

# Right-hand prompt
function RCMD() {
    if (( PROMPT_MODE == 0 )); then
        echo "$(RPR_INFO)$(git_prompt_string)$(RPR_EXTRA)"
    elif (( PROMPT_MODE <= 2 )); then
        echo "$(git_prompt_string)$(RPR_EXTRA)"
    else
        echo "$(RPR_EXTRA)"
    fi
}

# Async RPROMPT: compute RCMD in a process substitution and let zle read
# the result when it is ready (zle -F). No temp file: the old
# /tmp/zsh_prompt_$$ was predictable in a world-writable dir and never removed.
typeset -gi _rpr_fd=-1
function _rpr_done() {
    local fd=$1 out
    IFS= read -r -d '' -u $fd out
    zle -F $fd
    exec {fd}<&-
    (( fd == _rpr_fd )) && _rpr_fd=-1
    RPROMPT=${out%$'\n'} # RCMD echoes a newline; RPROMPT must be one line
    zle reset-prompt
}
# A widget (zle -F -w), so it may call reset-prompt.
zle -N _rpr_done

function _rpr_start() {
    # drop a still-running previous computation (it gets SIGPIPE on write)
    if (( _rpr_fd >= 0 )); then
        zle -F $_rpr_fd 2>/dev/null
        exec {_rpr_fd}<&-
        _rpr_fd=-1
    fi
    # do not clear RPROMPT, let it persist
    exec {_rpr_fd}< <(RCMD)
    zle -F -w $_rpr_fd _rpr_done
}
add-zsh-hook precmd _rpr_start
