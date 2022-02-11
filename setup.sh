#! bin/env bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

for FILE in "zsh" "zshrc" "bash" "bashrc" "shell" "vim" "vimrc" "tmux.conf" "condarc"
do
	if [ -e "$HOME/.$FILE" ] || [ -L "$HOME/.$FILE" ]
	then
		read -p "There already exist a .$FILE file in home. Replace with symlink? ([y]/n)" -n 1 -r
		if [[ $REPLY =~ ^[Yy]$ ]] || [ -z $REPLY ]
		then
			echo "removed $HOME/.$FILE and replaced with symlink"
			rm "$HOME/.$FILE";
			ln -s "$SCRIPTPATH/$FILE" "$HOME/.$FILE";
		else
			echo "did nothing"
		fi
	else 
		if ln -s "$SCRIPTPATH/$FILE" "$HOME/.$FILE";
		then
			echo "created symlink from $HOME/.$FILE to $SCRIPTPATH/$FILE"
		fi
	fi
done
