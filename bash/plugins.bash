# dircolors
if [[ "$(tput colors)" == "256" ]]; then
    eval "$(dircolors ~/.config/shell/plugins/dircolors-solarized/dircolors.256dark)"
fi
