[[ $- != *i* ]] && return
source /etc/bashrc
export PROFILE="bashrc"

## Check current platform and state
[ -z "$PS1" ] && return
[ "$TERM" = "nuclide" ] && return

function _profile_append {
    export PROFILE="$PROFILE:$1"
}

function _debug {
    if [[ -n "$DEBUG" ]]; then
        echo "$@"
    fi
}

# Add to default path
export PATH=/usr/local/bin:"$PATH"

# Setting up Rust env
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# Setting up Homebrew env
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Setting up ghcup env
if [[ -f "$HOME/.ghcup/env" ]]; then
    source "$HOME/.ghcup/env"
fi

## Grab-all for bash files
if [[ -d "$HOME"/.bash.d ]]; then
    for file in "$HOME"/.bash.d/*; do
        _profile_append "$file"
        source "$file"
    done
fi

## Happens after everything is setup
if [[ "$OS_PLATFORM" = linux ]]; then
    true
fi
