#!/bin/sh

HOME_ENV=`pwd`
DEFAULT_FILES="bash.d  bashrc bash_logout  emacs  gitconfig  gitignore hgrc profile pythonrc.py tmux.conf Xmodmap"
FILES=${@:-${DEFAULT_FILES}}

for FILE in ${FILES}
do
    need_link=1
    if [ -f ${HOME}/.${FILE} ]; then
	`diff -w -q ${HOME_ENV}/${FILE} ${HOME}/.${FILE} > /dev/null`
	need_link=${?}
	if [ ${need_link} -eq 1 ]; then
	    mv ${HOME}/.${FILE} ${HOME}/.${FILE}-
	fi
    elif [ -d ${HOME}/.${FILE} ]; then
	mv ${HOME}/.${FILE} ${HOME}/.${FILE}-
    fi

    if [ ${need_link} -eq 1 ]; then
	ln -s ${HOME_ENV}/${FILE} ${HOME}/.${FILE}
    fi
done
