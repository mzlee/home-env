#!/bin/bash
export PROFILE="bashrc"

# Add to default path
export PATH=/usr/local/bin:$PATH

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
BASH_DIR=$HOME/.bash.d
if [ -d $BASH_DIR ]; then
    for file in $(ls $BASH_DIR); do
	profile_append $file
	. $BASH_DIR/$file
    done
fi

## Happens after everything is setup
if [ $PLATFORM = linux ]; then
    true
fi

if [ -d '/lusr/opt/condor' ]; then
    # /lusr/opt/condor/bin/condor_vacate > /dev/null
    true
fi
