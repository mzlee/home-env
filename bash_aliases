# Bash Aliases

# ls aliases
alias la='ls -AF'
alias ll="ls -l"
alias l='ls -AlF'
alias sl="ls"

# emacs aliases
alias emacs="emacs -nw"
alias emasc="emacs -nw"
alias emac="emacs -nw"

# useful commands
alias wtf='watch -n 1 w -hs'

# removing default commands
alias g=""
alias s=""

alias less="less -R"
if [ "$PLATFORM" == "Linux" ]; then
   alias gopen="gnome-open"
fi

# svn commands
#alias svndiff='svn diff --diff-cmd colordiff -x "-u -w -p" "$@" | less'
#alias svnst='svn st | grep -v kbuild | grep -v db- | grep -v glibc | grep -v qemu-kvm'

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
