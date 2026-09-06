#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

echo "==> Dotfiles dir: $DOTFILES_DIR"
echo "==> Updating git submodules..."
git -C "$DOTFILES_DIR" submodule update --init --recursive

# ─── Package dependencies ────────────────────────────────────────────────────

echo "==> Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y \
    git curl wget unzip build-essential \
    cmake ninja-build pkg-config \
    clang clang-format clangd \
    lldb \
    tmux \
    python3 python3-pip python3-venv pipx \
    ripgrep fd-find fzf bat \
    nodejs npm \
    zsh \
    xclip wl-clipboard \
    vim \
    neovim

# ─── Neovim >= 0.11 ──────────────────────────────────────────────────────────

nvim_ok() {
    command -v nvim >/dev/null 2>&1 || return 1

    local version major minor rest
    version="$(nvim --version | head -n1 | sed -E 's/^NVIM v?([0-9]+)\.([0-9]+).*/\1.\2/')"
    major="${version%%.*}"
    rest="${version#*.}"
    minor="${rest%%.*}"

    [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1
    ((major > 0 || minor >= 11))
}

if nvim_ok; then
    echo "==> Neovim version OK: $(nvim --version | head -n1)"
else
    echo "==> Installing newer Neovim to ~/.local/opt/nvim..."
    tmpdir="$(mktemp -d)"

    curl -fsSL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz" |
        tar -xz -C "$tmpdir"

    extracted="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)"

    if [ -z "$extracted" ]; then
        echo "ERROR: failed to extract Neovim tarball" >&2
        rm -rf "$tmpdir"
        exit 1
    fi

    rm -rf "$HOME/.local/opt/nvim"
    mv "$extracted" "$HOME/.local/opt/nvim"
    ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmpdir"

    echo "==> Neovim installed: $(nvim --version | head -n1)"
fi

# ─── Debian command-name compatibility ───────────────────────────────────────

if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# ─── Rust ────────────────────────────────────────────────────────────────────

if ! command -v cargo >/dev/null 2>&1; then
    echo "==> Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# shellcheck source=/dev/null
source "$HOME/.cargo/env" 2>/dev/null || true

# ─── typos ───────────────────────────────────────────────────────────────────

if ! command -v typos >/dev/null 2>&1; then
    echo "==> Installing typos..."
    TYPOS_VER="1.28.2"
    tmpdir="$(mktemp -d)"

    curl -fsSL \
        "https://github.com/crate-ci/typos/releases/download/v${TYPOS_VER}/typos-v${TYPOS_VER}-x86_64-unknown-linux-musl.tar.gz" |
        tar -xz -C "$tmpdir"

    install -m 0755 "$tmpdir/typos" "$HOME/.local/bin/typos"
    rm -rf "$tmpdir"
fi

# ─── aichat ──────────────────────────────────────────────────────────────────

if ! command -v aichat >/dev/null 2>&1; then
    echo "==> Installing aichat..."
    cargo install aichat
fi

AICHAT_CONF_DIR="$HOME/.config/aichat"
mkdir -p "$AICHAT_CONF_DIR"

if [ ! -f "$AICHAT_CONF_DIR/config.yaml" ]; then
    cat >"$AICHAT_CONF_DIR/config.yaml" <<'AICHAT_EOF'
# aichat config - edit model and api_key to match your provider.
# You can either set an API key here or export the relevant environment variable.

clients:
  - type: openai
    # api_key: YOUR_API_KEY_HERE
    # model: gpt-4o

  # Local/offline option with Ollama:
  # - type: ollama
  #   api_base: http://127.0.0.1:11434
  #   models:
  #     - name: deepseek-coder-v2
  #       max_input_tokens: 65536

model: openai:gpt-4o
stream: true
AICHAT_EOF
    echo "    NOTE: edit ~/.config/aichat/config.yaml or export your API key."
fi

# ─── Ollama ──────────────────────────────────────────────────────────────────

if ! command -v ollama >/dev/null 2>&1; then
    echo "==> Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo "    Run 'ollama pull deepseek-coder-v2' to get a local coding model."
fi

# ─── TPM — Tmux Plugin Manager ───────────────────────────────────────────────

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "==> Installing TPM..."
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# ─── Neovim lazy.nvim bootstrap ──────────────────────────────────────────────

LAZY_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZY_DIR" ]; then
    echo "==> Installing lazy.nvim..."
    git clone --filter=blob:none --depth=1 \
        https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
fi

# ─── Symlinks ────────────────────────────────────────────────────────────────

echo "==> Linking dotfiles..."

link() {
    local rel="$1"
    local dst="$2"
    local src="$DOTFILES_DIR/$rel"
    local ts

    if [ ! -e "$src" ]; then
        echo "ERROR: missing source: $src" >&2
        return 1
    fi

    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        if [ "$(readlink "$dst")" = "$src" ]; then
            echo "    OK: $dst -> $src"
            return 0
        fi

        rm "$dst"
        echo "    Removed old symlink $dst"
    elif [ -e "$dst" ]; then
        ts="$(date +%s)"
        mv "$dst" "${dst}.bak.${ts}"
        echo "    Backed up existing $dst -> ${dst}.bak.${ts}"
    fi

    ln -s "$src" "$dst"
    echo "    Linked $dst -> $src"
}

link "bashrc" "$HOME/.bashrc"
link "zshrc" "$HOME/.zshrc"
link "inputrc" "$HOME/.inputrc"
link "condarc" "$HOME/.condarc"

link "bash" "$HOME/.config/bash"
link "zsh" "$HOME/.config/zsh"
link "shell" "$HOME/.config/shell"

link "nvim" "$HOME/.config/nvim"
link "tmux/tmux.conf" "$HOME/.tmux.conf"
link "kitty" "$HOME/.config/kitty"

link "git/gitconfig" "$HOME/.gitconfig"
link "git/gitignore_global" "$HOME/.gitignore_global"

# ─── tree-sitter CLI ─────────────────────────────────────────────────────────

if ! command -v tree-sitter >/dev/null 2>&1; then
    echo "==> Installing tree-sitter-cli..."
    TS_VER="0.24.6"
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TS_VER}/tree-sitter-linux-x64.gz" |
        gunzip >"$HOME/.local/bin/tree-sitter"
    chmod +x "$HOME/.local/bin/tree-sitter"
fi

# ─── TPM plugins ─────────────────────────────────────────────────────────────

echo "==> Installing tmux plugins..."
"$TPM_DIR/bin/install_plugins" 2>/dev/null || true

echo ""
echo "==> Done. Open a new shell, then:"
echo "    1. Start tmux — plugins are installed."
echo "    2. Open nvim — lazy.nvim syncs automatically on first launch."
echo "    3. Edit ~/.config/aichat/config.yaml or export your API key."
echo "    4. Optional: ollama pull deepseek-coder-v2"
