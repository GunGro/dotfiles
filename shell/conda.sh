# shellcheck shell=bash
# Lazy conda. `conda shell.* hook` costs 0.3-0.8 s per shell start, so define a
# stub that runs the hook on first use and then re-dispatches. condarc already
# sets auto_activate_base: false, so nothing is lost by deferring.
# Root: $CONDA_ROOT, else the first of ~/miniforge3, ~/miniconda3, ~/anaconda3.

_dot_conda_root() {
    local d
    for d in "${CONDA_ROOT:-}" "$HOME/miniforge3" "$HOME/miniconda3" "$HOME/anaconda3"; do
        if [ -n "$d" ] && [ -x "$d/bin/conda" ]; then
            echo "$d"
            return 0
        fi
    done
    return 1
}

if CONDA_ROOT="$(_dot_conda_root)"; then
    export CONDA_ROOT
    conda() {
        local sh=bash hook
        [ -n "${ZSH_VERSION:-}" ] && sh=zsh
        hook="$("$CONDA_ROOT/bin/conda" "shell.$sh" hook)" || return
        unset -f conda
        eval "$hook"
        conda "$@"
    }
else
    unset CONDA_ROOT
fi
unset -f _dot_conda_root
