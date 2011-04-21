# from the template file /lusr/share/udb/pub/dotfiles/profile
#
# This file is read and the commands in it are executed by the Bourne shell
# on login and whenever a new shell is forked.
#

# Get the system wide default PATH.  
# It provides access to software you need.  It differs from one
# platform to another.  The department staff maintains it as a
# basic part of your working environment.  We will be very reluctant
# to bail you out if you ignore this warning and munge your PATH.
# !! DO NOT REMOVE THIS BLOCK !!
if [ -f /lusr/lib/misc/path.sh ]; then
	. /lusr/lib/misc/path.sh
fi
# !! DO NOT REMOVE THIS BLOCK !!


# Okay, now modify PATH.
# To tailor your PATH, append or prepend directories to the
# default PATH in a colon-separated list and remove the "#" comment
# marker at the start of the line.  
# !! DO NOT replace the value of PATH !!
#	PATH=${HOME}/bin:${PATH}:/some/other/dir

# and must export PATH to make it part of the environment
export PATH


#eval `tset -s -e -k^U -m '98700:?hp98700' -m 'sun:?sun' -m 'network:?xterms' -m 'dialup:?vt100' -m 'unknown:?sun' -m 'su:?vt100'`
#export TERM


# Set a default printer for lpr and other print commands.
# To choose your favorite replace "lw7" with the printer you use
# most often and remove the "#" comment marker at the start of the line
# that sets and exports it.  
# If $PRINTER is not set, you have to tell lpr which printer to use with
# the -P option.  See 'man printers' for more info.
#	PRINTER=lw7 ; export PRINTER

MAIL=${HOME}/mailbox
MAILER=mush
EDITOR=vi
PS1="`uname -n`$ "
NNTPSERVER="newshost.cc.utexas.edu"

umask 077
export MAIL PS1 EDITOR MAILER
