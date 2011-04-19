#!/bin/sh
# from the template /lusr/share/udb/pub/dotfiles/xinitrc

# You may want to set up your own .Xresources for use with
# xrdb and .Xmodmap for use with xmodmap.
# If they don't exist yet, they simply are not used.
userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap

name=`hostname | sed 's/\..*//'`
# merge in defaults and keymaps
if [ -f $userresources ]; then
    xrdb -merge $userresources
fi
if [ -f $usermodmap ]; then
    xmodmap $usermodmap
fi

# see 'man X' for info on geometry specification
#xbiff -geometry 50x50+5+5 -volume 0 -file $HOME/mailbox/mailbox &

# see 'man xterm' for lots of options
#xterm -bg gray34 -fg wheat1 -geometry 80x45+375+155 -name $name &
#xterm  -bg sienna4 -fg blanchedalmond -C -name "${name}'s console" -geometry 80x10+0-0 &
#xterm -geometry 80x24+0+7 -name "$name" &

xterm -bg black4 &

# Start the window manager.  Run only this one in the foreground.
# Killing this window manager will shut down the X session.

startkde
