#!/bin/bash
export PROFILE="bashrc"

function profile_append {
    export PROFILE="$PROFILE:$1"
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
PROMPT_COMMAND=prompt_command
set_colors
