# .bashrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

## Prompt
TRUE="\033[1;32m"
FALSE="\033[1;31m"
NEUTRAL="\[\033[1;33m\]"
ACCENT="\[\033[1;30m\]"
LIGHT="\[\033[0;37m\]"
case "$HOSTNAME" in
    shappu2000)
	BASE="\[\033[0;36m\]"
	BOLD="\[\033[1;36m\]"
	;;
    habals)
	BASE="\[\033[0;33m\]"
	BOLD="\[\033[1;33m\]"
	;;
    dvorak)
	BASE="\[\033[0;34m\]"
	BOLD="\[\033[1;34m\]"
	;;
    *)
	BASE="\[\033[0;31m\]"
	BOLD="\[\033[1;31m\]"
	;;
esac

BOLD_RETURN=$(echo -e $NEUTRAL)

function prompt_command {
    if [[ $? = 0 ]]; then 
	BOLD_RETURN=$(echo -e $TRUE)
    else
	BOLD_RETURN=$(echo -e $FALSE)
    fi
}

PROMPT_COMMAND=prompt_command

function set_colors
{
    PS1="${debian_chroot:+($debian_chroot)}\${BOLD_RETURN}-$BOLD-($BASE\u$ACCENT@$BASE\h$ACCENT:$BASE\W$BOLD)-$LIGHT "
}
set_colors

export LS_COLORS="di=94:fi=0:ln=46:pi=32:so=32:bd=32:cd=32:or=41:mi=5:ex=32:*.rpm=90"

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

platform='unknown'
unamestr=`uname`
if [ "$unamestr" == 'Linux' ]
then
    platform='linux'
elif [ "$unamestr" == 'FreeBSD' ]
then
    platform='freebsd'
elif [ "$unamestr" == 'Darwin' ]
then
    platform='darwin'
fi

export PLATFORM=$platform
export MAIL=$HOME/mailbox
export EDITOR='emacs -nw'
export PRINTER='lw32'

export PYTHONSTARTUP="$HOME/.pythonrc.py"
