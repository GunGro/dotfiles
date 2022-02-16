#! bin/env bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"


if [ ! -f "$SCRIPTPATH/shell/local_aliases.sh" ]; then
    touch "$SCRIPTPATH/shell/local_aliases.sh"
fi

if [ ! -f "$SCRIPTPATH/shell/local_functions.sh" ]; then
    touch "$SCRIPTPATH/shell/local_functions.sh"
fi

if [ ! -f "$SCRIPTPATH/shell/local_changes.sh" ]; then
    touch "$SCRIPTPATH/shell/local_changes.sh"
fi

if [ ! -f "$SCRIPTPATH/zsh/local_aliases.zsh" ]; then
    touch "$SCRIPTPATH/zsh/local_aliases.zsh"
fi

if [ ! -f "$SCRIPTPATH/zsh/local_functions.zsh" ]; then
    touch "$SCRIPTPATH/zsh/local_functions.zsh"
fi

if [ ! -f "$SCRIPTPATH/zsh/local_changes.zsh" ]; then
    touch "$SCRIPTPATH/zsh/local_changes.zsh"
fi

if [ ! -f "$SCRIPTPATH/bash/local_aliases.bash" ]; then
    touch "$SCRIPTPATH/bash/local_aliases.bash"
fi

if [ ! -f "$SCRIPTPATH/bash/local_functions.bash" ]; then
    touch "$SCRIPTPATH/bash/local_functions.bash"
fi

if [ ! -f "$SCRIPTPATH/bash/local_changes.bash" ]; then
    touch "$SCRIPTPATH/bash/local_changes.bash"
fi

if [ ! -f "$SCRIPTPATH/local_gitconfig" ]; then
    touch "$SCRIPTPATH/local_gitconfig"
fi

# Add symlinks

for FILE in "zsh" "zshrc" "bash" "bashrc" "shell" "vim" "vimrc" "tmux.conf" "condarc"
do
	if [ -e "$HOME/.$FILE" ] || [ -L "$HOME/.$FILE" ]
	then
		read -p "There already exist a .$FILE file in home. Replace with symlink? ([y]/n)" -n 1 -r
        if [[ ! -z $REPLY ]]
        then
            echo
        fi
		if [[ $REPLY =~ ^[Yy]$ ]] || [ -z $REPLY ]
		then
			echo "removed $HOME/.$FILE and replaced with symlink"
			rm "$HOME/.$FILE";
			ln -s "$SCRIPTPATH/$FILE" "$HOME/.$FILE";
		else
			echo "Did nothing"
		fi
	else 
		if ln -s "$SCRIPTPATH/$FILE" "$HOME/.$FILE";
		then
			echo "created symlink from $HOME/.$FILE to $SCRIPTPATH/$FILE"
		fi
	fi
done

#  Fix gitconfig settings if desired

read -p "Do you want to include the custom gitconfig settings in your global gitconfig ([y]/n)" -n 1 -r
if [[ ! -z $REPLY ]]
then
    echo
fi
if [[ $REPLY =~ ^[Yy]$ ]] || [ -z $REPLY ]
then
    echo "running 'git config --global --replace-all  include.path $SCRIPTPATH/gitconfig'"
    git config --global --replace-all include.path "$SCRIPTPATH/gitconfig"
    echo "running 'git config --global --add include.path $SCRIPTPATH/local_gitconfig'"
    git config --global --add include.path "$SCRIPTPATH/local_gitconfig"
fi

# Fix YouCompleteME

read -p "Do you want to set up YouCompleteME ([y]/n)" -n 1 -r
if [[ ! -z $REPLY ]]
then
    echo
fi
if [[ $REPLY =~ ^[Yy]$ ]] || [ -z $REPLY ]
then
    echo "running 'sudo apt install build-essential cmake vim-nox python3-dev'"
    sudo apt install build-essential cmake vim-nox python3-dev
    echo "running 'sudo apt install mono-complete golang nodejs default-jdk npm'"
    sudo apt install mono-complete golang nodejs default-jdk npm
    cd "$SCRIPTPATH/vim/pack/vendor/start/YouCompleteMe"
    echo "running 'python3 install.py --all'"
    python3 install.py --all
else
    echo "Did nothing"
fi
