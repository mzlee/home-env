#!/bin/sh

DEFAULT_FILES="bash_aliases  bash_logout  bashrc  emacs  gitconfig  gitignore profile  pythonrc.py"
FILES=${@:-${DEFAULT_FILES}}

for FILE in ${FILES}
do
    if [ -f ${HOME}/.${FILE} ]
    then
	echo ${FILE}
	colordiff ${FILE} ${HOME}/.${FILE}
    else
	ln -s ${FILE} ${HOME}/.${FILE}
    fi
done
