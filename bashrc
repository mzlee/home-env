#!/bin/bash
export PROFILE="bashrc"

## Check current platform and state
[ -z "$PS1" ] && return
[ "$TERM" = "nuclide" ] && return

function profile_append {
    export PROFILE="$PROFILE:$1"
}

function debug {
    if [[ -n "$DEBUG" ]]; then
	echo "$@"
    fi
}

# Add to default path
export PATH=/usr/local/bin:"$PATH"

# Setting up Rust env
source "$HOME/.cargo/env"

# Setting up Homebrew env
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

## Grab-all for bash files
BASH_DIR="$HOME"/.bash.d
if [ -d "$BASH_DIR" ]; then
    for file in $(ls $BASH_DIR); do
	profile_append $file
	source "$BASH_DIR/$file"
    done
fi

## Happens after everything is setup
if [ "$OS_PLATFORM" = linux ]; then
    true
fi
