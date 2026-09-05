#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Dotfiles dir: $DOTFILES_DIR"

# ─── Package dependencies ────────────────────────────────────────────────────

echo "==> Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y \
    git curl wget unzip build-essential \
    cmake ninja-build pkg-config \
    clang clang-format clangd \
    lldb \
    tmux \
    python3 python3-pip pipx \
    ripgrep fd-find fzf bat \
    nodejs npm \
    neovim \
    vim

# Debian: fd is installed as fdfind, make an alias
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
fi

# ─── Rust (needed for typos, aichat) ─────────────────────────────────────────

if ! command -v cargo &>/dev/null; then
    echo "==> Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
# shellcheck source=/dev/null
source "$HOME/.cargo/env" 2>/dev/null || true

# ─── typos (LSP-compatible spell/typo checker) ────────────────────────────────

if ! command -v typos &>/dev/null; then
    echo "==> Installing typos (prebuilt binary)..."
    TYPOS_VER="1.28.2"
    curl -fsSL \
        "https://github.com/crate-ci/typos/releases/download/v${TYPOS_VER}/typos-v${TYPOS_VER}-x86_64-unknown-linux-musl.tar.gz" |
        tar -xz -C "$HOME/.local/bin" ./typos
    chmod +x "$HOME/.local/bin/typos"
fi

# ─── aichat (AI CLI tool, used in shell and tmux) ────────────────────────────

if ! command -v aichat &>/dev/null; then
    echo "==> Installing aichat..."
    cargo install aichat
fi

# aichat config directory
AICHAT_CONF_DIR="$HOME/.config/aichat"
mkdir -p "$AICHAT_CONF_DIR"

# Write config only if it doesn't already exist (don't overwrite user's API key)
if [ ! -f "$AICHAT_CONF_DIR/config.yaml" ]; then
    cat >"$AICHAT_CONF_DIR/config.yaml" <<'EOF'
# aichat config - edit model and api_key to match your provider
# Supported clients: openai, anthropic, ollama (local/free), gemini, ...

clients:
  - type: openai
    api_key: YOUR_API_KEY_HERE   # replace or set OPENAI_API_KEY env var
    # model: gpt-4o              # optional override

  # Uncomment for local/offline use with Ollama:
  # - type: ollama
  #   api_base: http://127.0.0.1:11434
  #   models:
  #     - name: deepseek-coder-v2
  #       max_input_tokens: 65536

model: openai:gpt-4o
stream: true
EOF
    echo "    NOTE: edit ~/.config/aichat/config.yaml to set your API key."
fi

# ─── Ollama (optional local LLM backend) ──────────────────────────────────────

if ! command -v ollama &>/dev/null; then
    echo "==> Installing Ollama (local LLM backend)..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "    Run 'ollama pull deepseek-coder-v2' to get a coding model."
fi

# ─── TPM — Tmux Plugin Manager ────────────────────────────────────────────────

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "==> Installing TPM..."
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ─── Neovim — lazy.nvim bootstrap ────────────────────────────────────────────

LAZY_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZY_DIR" ]; then
    echo "==> Installing lazy.nvim..."
    git clone --filter=blob:none --depth=1 \
        https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
fi

# ─── Symlinks ────────────────────────────────────────────────────────────────

echo "==> Linking dotfiles..."

link() {
    local src="$DOTFILES_DIR/$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "${dst}.bak.$(date +%s)"
        echo "    Backed up existing $dst"
    fi
    ln -sfn "$src" "$dst"
    echo "    $dst -> $src"
}

link "nvim" "$HOME/.config/nvim"
link "vim/.vimrc" "$HOME/.vimrc"
link "shell/aliases.sh" "$HOME/.config/shell/aliases.sh"
link "tmux/.tmux.conf" "$HOME/.tmux.conf"
link "git/.gitconfig" "$HOME/.gitconfig"

# Source aliases from .bashrc / .zshrc if not already present
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ] && ! grep -q "aliases.sh" "$rcfile"; then
        echo "[ -f \"\$HOME/.config/shell/aliases.sh\" ] && source \"\$HOME/.config/shell/aliases.sh\"" >>"$rcfile"
        echo "    Added aliases.sh source to $rcfile"
    fi
done

# Add ~/.local/bin and ~/.cargo/bin to PATH if missing
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ] && ! grep -q '\.local/bin' "$rcfile"; then
        echo 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"' >>"$rcfile"
    fi
done

echo "==> installing tree-sitter-cli"
TS_VER="0.24.6"
curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TS_VER}/tree-sitter-linux-x64.gz" |
    gunzip >"$HOME/.local/bin/tree-sitter"
chmod +x "$HOME/.local/bin/tree-sitter"

# ─── TPM: install tmux plugins headlessly ────────────────────────────────────

echo "==> Installing tmux plugins..."
"$TPM_DIR/bin/install_plugins" 2>/dev/null || true

echo ""
echo "==> Done. Open a new shell, then:"
echo "    1. Start tmux — plugins are installed."
echo "    2. Open nvim — lazy.nvim syncs automatically on first launch."
echo "    3. Edit ~/.config/aichat/config.yaml with your API key."
echo "    4. Optional: ollama pull deepseek-coder-v2   (for offline use)"
