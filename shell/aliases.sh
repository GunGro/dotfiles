# Editor 

alias vim='nvim'
alias vi='nvim'
alias v='nvim'

# Cmake / Build
alias cmake-init='cmake -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON'
alias cmake-build='cmake --build build'
alias cmake-clean='rm -rf build'
alias cmake-rebuild='cmake-clean && cmake-init && cmake-build'

# Symlink compile_commands.json to project root (clangd needs it)
alias cmake-link='ln -sf build/compile_commands.json .'

# Full fresh configure + build + link in one shot
alias cmake-fresh='cmake-clean && cmake-init && cmake-build && cmake-link'

# Colors from coreutils utilities output
alias ls='ls --color=auto'
alias grep='grep --color'

# Navigation

alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

# ls aliases
alias ll='ls -lahF'
alias la='ls -AF'
alias l='ls'

# clear
alias c='clear'
# git
alias gag='git exec ag'

# shutoff/exit shortcuts
alias s='shutdown -h'
alias e='exit'


# git root
alias cdgr='cd $(git root)'

# ssh
alias sshx="ssh -X"
