# dircolors
if command -v dircolors >/dev/null 2>&1 && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
    eval "$(dircolors "$HOME/.config/shell/plugins/dircolors-solarized/dircolors.256dark")"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# fzf keybindings (Ctrl+T: fuzzy file insert, Alt+C: fuzzy cd)
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi
