# from the template file /lusr/share/udb/pub/dotfiles/cshrc
#
# This file is read by the C shell (csh) every time it starts up.
#

# Determine if this is an interactive shell, e.g., the login shell
# or a shell forked by an editor.
if ($?prompt) then
#	yes, login shell

# remember the last 20 commands executed and save them across logins
	set history = 20 savehist = 20

# set up a shorter name for the history command
	alias h history

# and a shorter name for the jobs command
	alias j jobs

else

# give me the default path when I "rsh" 
	if (-f /lusr/lib/misc/path.csh) then
		source /lusr/lib/misc/path.csh
	endif
	
endif

#
