#!/bin/bash
export PROFILE="bashrc"

function profile_append {
    export PROFILE="$PROFILE:$1"
}

function debug {
    if [ -n "${DEBUG}" ]
    then
	echo $@
    fi
}

## Check current platform and state
[ -z "$PS1" ] && return

## Grab-all for bash files
BASH_DIR=~/.bash.d
if [ -d $BASH_DIR ]; then
    files=`ls $BASH_DIR`
    for file in $files; do
	profile_append $file
	. $BASH_DIR/$file
    done
fi

## Happens after everything is setup
if [ $PLATFORM = linux ]
then
#    PROMPT_COMMAND=prompt_command
    set_colors
#    pub_machine
fi

if [ -d '/lusr/opt/condor' ]
then
    # /lusr/opt/condor/bin/condor_vacate > /dev/null
fi
