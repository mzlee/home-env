#!/bin/sh

HOME_ENV=`pwd`
DEFAULT_FILES="bash.d  bashrc bash_logout  emacs  gitconfig  gitignore profile pythonrc.py Xmodmap"
FILES=${@:-${DEFAULT_FILES}}

for FILE in ${FILES}
do
    need_link=1
    if [ -f ${HOME}/.${FILE} ]
    then
	`diff -w -q ${HOME_ENV}/${FILE} ${HOME}/.${FILE} > /dev/null`
	need_link=${?}
	if [ ${?} -eq 1 ]
	then
	    mv ${HOME}/.${FILE} ${HOME}/.${FILE}-
	fi
    elif [ -d ${HOME}/.${FILE} ]
    then
	rm ${HOME}/.${FILE}
    fi

    if [ ${need_link} -eq 1 ]
    then
	ln -s ${HOME_ENV}/${FILE} ${HOME}/.${FILE}
    fi
done
