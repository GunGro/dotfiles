#! bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Dotfiles dir: $DOTFILES"

sudo apt update && sudo apt install -y \
    neovim \
    clang \
    clang-format \
    cmake \
    ninja-build \
    gdb \
    valgrind \
    git \
    curl \
    wget \
    zsh \
    tmux \
    ripgrep \
    fd-find \
    fzf \
    make \
    python3 \
    python3-pip

# Neovim config -------------------------------------------------

echo "==> Linking Neovim config..."
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/nvim" "$HOME/.config/nvim"

# Shell configs ------------------------------------------------

echo "==> Linking shell configs..."
ln -sf "$DOTFILES/zshrc"   "$HOME/.zshrc"
ln -sf "$DOTFILES/bashrc"  "$HOME/.bashrc"
ln -sf "$DOTFILES/tmux.conf" "$HOME/.tmux.conf"

# Git configs ---------------------------------

echo "==> Linking git config..."
ln -sf "$DOTFILES/gitconfig"        "$HOME/.gitconfig"
ln -sf "$DOTFILES/gitignore_global" "$HOME/.gitignore_global"

# Done ---------------------

echo "==> Setup Complete"
