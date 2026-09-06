# dotfiles

Personal Debian/Ubuntu-oriented dotfiles for Bash, Zsh, Git, tmux and Neovim.

## Installation

Run `bash path_to_repository/setup.bash` from anywhere.

The setup script installs required packages, initializes submodules, installs shell/editor tooling, and links the config files into `$HOME`.

## Includes

- Bash and Zsh configuration
- Shared shell aliases and functions
- Zsh completions and syntax highlighting
- Neovim configuration using `lazy.nvim`
- tmux configuration with TPM plugins
- Git configuration and global ignore rules
- Modern CLI tooling: zoxide, eza, btop, lazygit, git-delta

## Local changes

Use the `*_local` and `local_*` files for machine-specific changes. These files are ignored by Git.
