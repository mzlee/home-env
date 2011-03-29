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
alias brload=". ~/.bashrc"
alias note="touch "`date +%y.%m.%d`".inktag.yml"
alias wtf='watch -n 1 w -hs'

# removing default commands
alias g=""
alias s=""

alias less="less -R"
alias gopen="gnome-open"

# svn commands
#alias svndiff='svn diff --diff-cmd colordiff -x "-u -w -p" "$@" | less
#alias svnst='svn st | grep -v kbuild | grep -v db- | grep -v glibc | grep -v qemu-kvm'
