#! bin/env bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

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
    echo "running 'git config --global --add include.path $SCRIPTPATH/gitconfig_local'"
    git config --global --add include.path "$SCRIPTPATH/gitconfig_local"
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



