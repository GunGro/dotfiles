#!/usr/bin/env bash
# Dotfiles installer (Debian/Ubuntu; x86_64, partly aarch64).
#
#   bash setup.bash                  core + dev (default)
#   bash setup.bash --all            core + dev + ai + gamedev
#   bash setup.bash --core --ai      pick modules (core is always included)
#   bash setup.bash --links-only     only symlink configs (any distro)
#   bash setup.bash --dry-run ...    show what would happen, change nothing
#
# Modules:
#   core     shell, tmux, Neovim (>= 0.11), git + delta/lazygit, eza, atuin, symlinks
#   dev      C/C++ toolchain (cmake, ninja, clang, clangd, gdb/lldb, ccache, mold),
#            git-lfs, node, rust, typos, yq, watchexec, global git hooks, debugger configs
#   ai       aichat (+ config template), Ollama
#   gamedev  Godot helpers: perf/hotspot/heaptrack, systemd-coredump, gdtoolkit,
#            visidata, godot-nvim bridge; Godot itself with GODOT_VER=4.x.y-stable
#   gaming   Windows games via Lutris (Flatpak, GE-Proton/umu, DXVK/VKD3D):
#            driver/Vulkan check, gamemode, prefixes under GAMES_DIR
#            (default /srv/data/games). Not part of --all.
#
# Re-running is safe: installed tools are skipped, existing files are backed up
# to *.bak.<timestamp> before being replaced by symlinks.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Options ─────────────────────────────────────────────────────────────────

DRY=0
LINKS_ONLY=0
MODULES=()

usage() { sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
    case "$1" in
        --core | --dev | --ai | --gamedev | --gaming) MODULES+=("${1#--}") ;;
        --all) MODULES=(core dev ai gamedev) ;;
        --links-only) LINKS_ONLY=1 ;;
        -n | --dry-run) DRY=1 ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done
[ "${#MODULES[@]}" -gt 0 ] || MODULES=(core dev)
case " ${MODULES[*]} " in *" core "*) ;; *) MODULES=(core "${MODULES[@]}") ;; esac

has_module() { case " ${MODULES[*]} " in *" $1 "*) return 0 ;; esac; return 1; }

# ─── Helpers ─────────────────────────────────────────────────────────────────

say() { echo "==> $*"; }
warn() { echo "    WARN: $*" >&2; }

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64) NVIM_ARCH=x86_64 ;;
    aarch64 | arm64) NVIM_ARCH=arm64 ;;
    *) NVIM_ARCH="" ;;
esac

# need CMD [LABEL] [x86]: true if CMD is missing and should be installed now.
# Dry run: report and return false. "x86": only a prebuilt x86_64 binary exists.
need() {
    command -v "$1" >/dev/null 2>&1 && return 1
    if [ "${3:-}" = x86 ] && [ "$ARCH" != x86_64 ]; then
        warn "no prebuilt ${2:-$1} for $ARCH, skipping"
        return 1
    fi
    if [ "$DRY" = 1 ]; then
        echo "    would install: ${2:-$1}"
        return 1
    fi
    say "Installing ${2:-$1}..."
}

APT_PKGS=()
apt_add() { APT_PKGS+=("$@"); }

apt_install() {
    [ "${#APT_PKGS[@]}" -gt 0 ] || return 0
    if ! command -v apt-get >/dev/null 2>&1; then
        warn "apt-get not found; install these yourself, then rerun with --links-only:"
        echo "    ${APT_PKGS[*]}"
        return 0
    fi
    if [ "$DRY" = 1 ]; then
        echo "    would apt-get install: ${APT_PKGS[*]}"
        return 0
    fi
    say "Installing system packages..."
    sudo apt-get update -qq
    # Install what this release has; report the rest instead of aborting.
    local available=() missing=() p
    for p in "${APT_PKGS[@]}"; do
        if apt-cache show "$p" >/dev/null 2>&1; then available+=("$p"); else missing+=("$p"); fi
    done
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${available[@]}"
    [ "${#missing[@]}" -eq 0 ] || warn "not in apt here, skipped: ${missing[*]}"
}

# gh_bin NAME URL [PATH_IN_TARBALL]: install one binary from a release tarball.
gh_bin() {
    local name="$1" url="$2" inner="${3:-$1}" tmp
    tmp="$(mktemp -d)"
    if curl -fsSL "$url" | tar -xz -C "$tmp"; then
        install -m 0755 "$tmp/$inner" "$HOME/.local/bin/$name"
    else
        warn "download failed for $name"
    fi
    rm -rf "$tmp"
}

latest_tag() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": *"\K[^"]*' || true; }

ensure_rust() {
    command -v cargo >/dev/null 2>&1 && return 0
    if [ "$DRY" = 1 ]; then
        echo "    would install: rust (rustup)"
        return 0
    fi
    say "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env" 2>/dev/null || true
}

git_clone_once() { # URL DIR
    [ -d "$2" ] && return 0
    if [ "$DRY" = 1 ]; then
        echo "    would clone: $1"
        return 0
    fi
    git clone --depth=1 "$1" "$2"
}

link() {
    local rel="$1" dst="$2" src="$DOTFILES_DIR/$1" ts

    if [ ! -e "$src" ]; then
        echo "ERROR: missing source: $src" >&2
        return 1
    fi
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "    OK: $dst"
        return 0
    fi
    if [ "$DRY" = 1 ]; then
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            echo "    would back up $dst, then link it -> $rel"
        else
            echo "    would link $dst -> $rel"
        fi
        return 0
    fi

    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        ts="$(date +%s)"
        mv "$dst" "${dst}.bak.${ts}"
        echo "    Backed up $dst -> ${dst}.bak.${ts}"
    fi
    ln -s "$src" "$dst"
    echo "    Linked $dst -> $rel"
}

# ─── Modules: packages ───────────────────────────────────────────────────────

core_packages() {
    apt_add git curl wget unzip build-essential \
        tmux zsh vim xclip wl-clipboard \
        python3 python3-pip python3-venv pipx \
        ripgrep fd-find fzf bat zoxide btop ncdu direnv jq eza
}

dev_packages() {
    apt_add cmake ninja-build pkg-config \
        clang clang-format clangd lldb gdb \
        ccache mold git-lfs shellcheck nodejs npm
}

gamedev_packages() {
    apt_add hotspot heaptrack heaptrack-gui systemd-coredump ipython3 \
        linux-tools-common "linux-tools-$(uname -r)"
}

gaming_packages() {
    apt_add flatpak vulkan-tools gamemode
}

# ─── Modules: tools ──────────────────────────────────────────────────────────

nvim_ok() {
    command -v nvim >/dev/null 2>&1 || return 1
    local v major minor
    v="$(nvim --version | head -n1 | sed -E 's/^NVIM v?([0-9]+)\.([0-9]+).*/\1.\2/')"
    major="${v%%.*}"
    minor="${v#*.}"
    [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1
    ((major > 0 || minor >= 11))
}

core_tools() {
    # Neovim >= 0.11 (native vim.lsp API); distro packages are often older.
    if ! nvim_ok; then
        if [ -z "$NVIM_ARCH" ]; then
            warn "no Neovim build for $ARCH; install Neovim >= 0.11 yourself"
        elif [ "$DRY" = 1 ]; then
            echo "    would install: Neovim stable -> ~/.local/opt/nvim"
        else
            say "Installing Neovim stable to ~/.local/opt/nvim..."
            local tmp
            tmp="$(mktemp -d)"
            curl -fsSL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${NVIM_ARCH}.tar.gz" |
                tar -xz -C "$tmp"
            rm -rf "$HOME/.local/opt/nvim"
            mv "$tmp/nvim-linux-${NVIM_ARCH}" "$HOME/.local/opt/nvim"
            ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
            rm -rf "$tmp"
        fi
    fi

    # Debian names some commands differently.
    if [ "$DRY" = 0 ]; then
        if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
            ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        fi
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
            ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        fi
    fi

    # eza: apt on newer releases, else prebuilt. (Not cargo: its palette
    # dependency has broken on stable rustc for some version combinations.)
    if need eza eza x86; then
        gh_bin eza "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
    fi

    if need lazygit lazygit x86; then
        local v
        v="$(latest_tag jesseduffield/lazygit)"
        if [ -n "$v" ]; then
            gh_bin lazygit "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${v#v}_Linux_x86_64.tar.gz"
        else
            warn "could not determine latest lazygit version"
        fi
    fi

    if need delta git-delta x86; then
        local v
        v="$(latest_tag dandavison/delta)"
        if [ -n "$v" ]; then
            gh_bin delta "https://github.com/dandavison/delta/releases/download/${v}/delta-${v}-x86_64-unknown-linux-gnu.tar.gz" \
                "delta-${v}-x86_64-unknown-linux-gnu/delta"
        else
            warn "could not determine latest git-delta version"
        fi
    fi

    # Needed by nvim-treesitter (main branch) to build parsers; it requires
    # tree-sitter-cli >= 0.25, so take the latest release, not a pinned 0.24.
    if need tree-sitter tree-sitter-cli x86; then
        curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz" |
            gunzip >"$HOME/.local/bin/tree-sitter"
        chmod +x "$HOME/.local/bin/tree-sitter"
    fi

    # The release installer directly, with ATUIN_NO_MODIFY_PATH=1: setup.atuin.sh
    # appends PATH and `atuin init` lines to ~/.bashrc/~/.zshrc, which are
    # symlinks into this repo (shell/plugins_common.sh already does both).
    if need atuin; then
        curl --proto '=https' --tlsv1.2 -LsSf https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh |
            ATUIN_NO_MODIFY_PATH=1 sh
    fi

    git_clone_once https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    git_clone_once https://github.com/folke/lazy.nvim.git "$HOME/.local/share/nvim/lazy/lazy.nvim"
}

dev_tools() {
    ensure_rust

    if need typos typos x86; then
        gh_bin typos "https://github.com/crate-ci/typos/releases/download/v1.28.2/typos-v1.28.2-x86_64-unknown-linux-musl.tar.gz"
    fi

    if need yq; then
        local a=amd64
        [ "$ARCH" = x86_64 ] || a=arm64
        curl -fsSL -o "$HOME/.local/bin/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${a}" &&
            chmod +x "$HOME/.local/bin/yq"
    fi

    if need watchexec; then
        cargo install watchexec-cli
    fi
}

ai_tools() {
    ensure_rust
    if need aichat; then
        cargo install aichat
    fi

    local conf="$HOME/.config/aichat/config.yaml"
    if [ ! -f "$conf" ]; then
        if [ "$DRY" = 1 ]; then
            echo "    would write: $conf (template, no key)"
        else
            mkdir -p "$(dirname "$conf")"
            cat >"$conf" <<'AICHAT_EOF'
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
            echo "    NOTE: edit $conf or export your API key."
        fi
    fi

    if need ollama; then
        curl -fsSL https://ollama.com/install.sh | sh
    fi
}

gamedev_tools() {
    if need gdformat gdtoolkit; then
        pipx install "gdtoolkit==4.*" || warn "gdtoolkit install failed"
    fi
    if need vd visidata; then
        pipx install visidata || warn "visidata install failed"
    fi

    if [ -n "${GODOT_VER:-}" ] && need godot "Godot ${GODOT_VER}" x86; then
        local tmp zip="Godot_v${GODOT_VER}_linux.x86_64.zip"
        tmp="$(mktemp -d)"
        if curl -fsSL -o "$tmp/$zip" "https://github.com/godotengine/godot/releases/download/${GODOT_VER}/${zip}"; then
            mkdir -p "$HOME/.local/opt/godot"
            unzip -oq "$tmp/$zip" -d "$HOME/.local/opt/godot"
            ln -sf "$HOME/.local/opt/godot/Godot_v${GODOT_VER}_linux.x86_64" "$HOME/.local/bin/godot"
        else
            warn "could not download Godot ${GODOT_VER}"
        fi
        rm -rf "$tmp"
    fi

    # apport (Ubuntu) re-takes kernel.core_pattern and ignores unpackaged
    # binaries such as Godot; systemd-coredump keeps them.
    if systemctl is-enabled apport >/dev/null 2>&1; then
        echo "    NOTE: apport is enabled; for gdcore run: sudo systemctl disable --now apport"
        echo "          and sudo sysctl -p /usr/lib/sysctl.d/50-coredump.conf"
    fi
}

GAMES_DIR="${GAMES_DIR:-/srv/data/games}"
LUTRIS=net.lutris.Lutris

gaming_tools() {
    # Proprietary NVIDIA driver: Proton needs it (nouveau has no usable Vulkan).
    if lspci 2>/dev/null | grep -qi 'vga.*nvidia'; then
        if nvidia-smi >/dev/null 2>&1; then
            say "NVIDIA driver $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)"
        else
            warn "NVIDIA GPU without a working driver; run: sudo ubuntu-drivers install, then reboot"
        fi
    fi
    if command -v vulkaninfo >/dev/null 2>&1 && ! vulkaninfo --summary >/dev/null 2>&1; then
        warn "vulkaninfo fails: Proton (DXVK/VKD3D) will not run until Vulkan works"
    fi

    if [ "$DRY" = 1 ]; then
        echo "    would add flathub (--user), install $LUTRIS, grant $GAMES_DIR"
    elif ! command -v flatpak >/dev/null 2>&1; then
        warn "flatpak missing; skipping Lutris"
        return 0
    else
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        if ! flatpak info --user "$LUTRIS" >/dev/null 2>&1; then
            say "Installing Lutris (Flatpak)..."
            flatpak install --user -y --noninteractive flathub "$LUTRIS"
        fi
        # Also pulls the GL.nvidia-<version> runtime extension that matches the
        # host driver; rerun after every NVIDIA driver upgrade.
        flatpak update --user -y --noninteractive
    fi

    if [ ! -d "$GAMES_DIR" ]; then
        if [ -w "$(dirname "$GAMES_DIR")" ]; then
            [ "$DRY" = 1 ] || mkdir -p "$GAMES_DIR"
        else
            echo "    NOTE: create the games dir, then rerun with --gaming:"
            echo "          sudo install -d -o $(id -un) -g $(id -gn) $GAMES_DIR"
            return 0
        fi
    fi
    [ "$DRY" = 1 ] || flatpak override --user --filesystem="$GAMES_DIR" "$LUTRIS"
}

# ─── Modules: links ──────────────────────────────────────────────────────────

core_links() {
    link "bashrc" "$HOME/.bashrc"
    link "zshrc" "$HOME/.zshrc"
    link "zshenv" "$HOME/.zshenv"
    link "inputrc" "$HOME/.inputrc"
    link "bash" "$HOME/.config/bash"
    link "zsh" "$HOME/.config/zsh"
    link "shell" "$HOME/.config/shell"
    link "nvim" "$HOME/.config/nvim"
    link "tmux/tmux.conf" "$HOME/.tmux.conf"
    link "kitty" "$HOME/.config/kitty"
    link "git/gitconfig" "$HOME/.gitconfig"
    link "git/gitignore_global" "$HOME/.gitignore_global"
}

dev_links() {
    link "git/template" "$HOME/.config/git/template"
    link "gdb/gdbinit" "$HOME/.gdbinit"
    link "lldb/lldbinit" "$HOME/.lldbinit"
    link "clangd" "$HOME/.config/clangd"
}

gamedev_links() {
    link "bin/godot-nvim" "$HOME/.local/bin/godot-nvim"
}

# Machine-local files: created once from *.example, never overwritten.
local_files() {
    local ex dst
    for ex in "$DOTFILES_DIR"/shell/*.example; do
        [ -f "$ex" ] || continue
        dst="${ex%.example}"
        [ -e "$dst" ] && continue
        if [ "$DRY" = 1 ]; then
            echo "    would create ${dst#"$DOTFILES_DIR"/} from its .example"
        else
            cp "$ex" "$dst"
            echo "    Created ${dst#"$DOTFILES_DIR"/}"
        fi
    done
    if [ ! -f "$HOME/.gitconfig_local" ]; then
        if [ "$DRY" = 1 ]; then
            echo "    would create ~/.gitconfig_local"
        else
            cp "$DOTFILES_DIR/git/gitconfig_local.example" "$HOME/.gitconfig_local"
            echo "    Created ~/.gitconfig_local (set your name and email)"
        fi
    fi
    # Older examples set a placeholder identity, which beat useConfigOnly.
    if [ -f "$HOME/.gitconfig_local" ] &&
        [ "$(git config --file "$HOME/.gitconfig_local" user.email 2>/dev/null)" = you@example.com ]; then
        echo "    WARNING: ~/.gitconfig_local still has the placeholder user.email; set or remove it" >&2
    fi
}

# ─── Run ─────────────────────────────────────────────────────────────────────

[ "$DRY" = 1 ] && say "Dry run: nothing will be changed"
say "Dotfiles: $DOTFILES_DIR"

if [ "$DRY" = 0 ]; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/opt" "$HOME/.local/state"
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    git -C "$DOTFILES_DIR" submodule update --init --recursive
fi

if [ "$LINKS_ONLY" = 0 ]; then
    say "Modules: ${MODULES[*]}"
    for m in "${MODULES[@]}"; do
        if declare -F "${m}_packages" >/dev/null; then "${m}_packages"; fi
    done
    apt_install
    for m in "${MODULES[@]}"; do
        if declare -F "${m}_tools" >/dev/null; then "${m}_tools"; fi
    done
fi

say "Local files"
local_files

say "Linking"
for m in "${MODULES[@]}"; do
    if declare -F "${m}_links" >/dev/null; then "${m}_links"; fi
done

if [ "$DRY" = 0 ] && [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || true
fi

echo ""
say "Done. Open a new shell, then:"
echo "    - Edit shell/local_env.sh to turn on optional parts (game dev env, personal aliases)."
echo "    - Start tmux and nvim once: plugins install on first launch."
if has_module ai; then echo "    - aichat: edit ~/.config/aichat/config.yaml or export your API key."; fi
if has_module gamedev; then echo "    - Godot: Editor Settings → Text Editor → External: ~/.local/bin/godot-nvim, flags '{file} {line} {col}'."; fi
if has_module gaming; then echo "    - Lutris: install Battle.net with prefix $GAMES_DIR/battlenet (see README, Gaming)."; fi
if has_module dev; then echo "    - Run 'git init' once in existing repos to install the global pre-commit hook."; fi
