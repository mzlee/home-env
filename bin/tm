#!/bin/bash -e

TRASH_FOLDER='._trash'
FILES=$@

if [ ! -d ${HOME}/${TRASH_FOLDER} ]; then
    mkdir ${HOME}/${TRASH_FOLDER}
fi

for f in ${FILES}; do
    target=${f}
    if [ -f ${HOME}/${TRASH_FOLDER}/${target} ]; then
	counter=1
	while [ -f ${HOME}/${TRASH_FOLDER}/${target}.${counter} ]; do
	    let counter=counter+1
	done
	target=${target}.${counter}
    fi
    mv ${f} ${HOME}/${TRASH_FOLDER}/${target}
done
