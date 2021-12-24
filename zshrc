#!/bin/zsh
export PROFILE="zshrc"

## Check current platform and state
[[ -z "$PS1" ]] && return
[[ "$TERM" = "nuclide" ]] && return

function _profile_append {
    export PROFILE="$PROFILE:$1"
}

function _debug {
    if [[ -n "$DEBUG" ]]; then
	echo "$@"
    fi
}

if [[ -d "$HOME"/.zsh.d/ ]]; then
    for file in "$HOME"/.zsh.d/*; do
	_profile_append "$file"
	source "$file"
    done
fi
