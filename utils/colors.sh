#!/bin/bash
#
## Original Source:
## http://bitmote.com/index.php?post/2012/11/19/Using-ANSI-Color-Codes-to-Colorize-Your-Bash-Prompt-on-Linux#256%20%288-bit%29%20Colors
#
# generates an 8 bit color table (256 colors) for reference,
# using the ANSI CSI+SGR \033[48;5;${val}m for background and
# \033[38;5;${val}m for text (see "ANSI Code" on Wikipedia)
#

echo -en "\n   +  "
for i in $(seq 0 35); do
    printf "%2b " $i
done
printf "\n\n %3b  " 0
for i in $(seq 0 15); do
    echo -en "\033[48;5;${i}m  \033[m "
done
for i in $(seq 0 6); do
    i=$(( i * 36 + 16 ))
    printf "\n\n %3b  " ${i}
    for j in $(seq 0 35); do
	echo -en "\033[48;5;$(( i + j))m  \033[m "
    done
done
echo -e "\n"
