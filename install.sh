#!/bin/sh

HOME_ENV=`pwd`
DEFAULT_FILES="bash.d  bash_login  bash_logout  emacs  gitconfig  gitignore profile pythonrc.py"
FILES=${@:-${DEFAULT_FILES}}

for FILE in ${FILES}
do
    if [ -f ${HOME}/.${FILE} ]
    then
	`diff -w -q ${HOME_ENV}/${FILE} ${HOME}/.${FILE} > /dev/null`
	if [ ${?} -eq 1 ]
	then
	    mv ${HOME}/.${FILE} ${HOME}/.${FILE}-
	    ln -s ${HOME_ENV}/${FILE} ${HOME}/.${FILE}
	fi
    else
	ln -s ${HOME_ENV}/${FILE} ${HOME}/.${FILE}
    fi
done
