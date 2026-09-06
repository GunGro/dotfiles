# dircolors
if command -v dircolors >/dev/null 2>&1 && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
    eval "$(dircolors "$HOME/.config/shell/plugins/dircolors-solarized/dircolors.256dark")"
fi
