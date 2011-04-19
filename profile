# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# !! DO NOT REMOVE THIS BLOCK !!
if [ -f /lusr/lib/misc/path.sh ]; then
	. /lusr/lib/misc/path.sh
fi
# !! DO NOT REMOVE THIS BLOCK !!

export PATH=${HOME}/bin${PATH}:
export PRINTER=lw32
export EDITOR=emacs

echo $HOSTNAME
case "$HOSTNAME" in
    habals|dvorak)
	PUBLIC_MACHINE=0
	;;
    *)
	PUBLIC_MACHINE=1
	;;
esac

if [ $PUBLIC_MACHINE ]; then
    echo Public Machine
else
    echo Private Machine
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi
