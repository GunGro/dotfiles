# dircolors
if command -v dircolors >/dev/null 2>&1 && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
    eval "$(dircolors "$HOME/.config/shell/plugins/dircolors-solarized/dircolors.256dark")"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
    alias cd='z'
fi
