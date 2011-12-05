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

FQDN=`hostname -f`
case "$FQDN" in
    *.csres.utexas.edu)
	PUBLIC_MACHINE=0
	;;
    *.cs.utexas.edu)
	PUBLIC_MACHINE=1
	;;
    *)
        echo ${FQDN}
        PUBLIC_MACHINE=1
        ;;
esac

export FQDN

if [ $PUBLIC_MACHINE -eq 1 ]; then
    umask 077
else
    umask 022
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi
