#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys

COLOR = u'\x1b[%s'
recolor = dict(
    dunk = (COLOR % ('38;5;28m')),
    dune = (COLOR % ('38;5;4m')),
    guest = (COLOR % ('38;5;1m')),
    qemu = (COLOR % ('38;5;52m')),
)

def write_out(str):
    sys.stdout.write(str.encode('utf-8'))
    sys.stdout.flush()

def main(fin):
    done = False
    checked = False
    line = ""
    while not done:
        c = fin.read(1)
        if not c: break

        if c == '\n':
            if not checked:
                write_out(line)
            checked = False
            line = ""
            write_out(COLOR % '0m')
            write_out('\n')
            continue
        if checked:
            write_out(c)
            continue

        line += c
        try:
            tag = line.split(':', 1)[0]
            line = recolor[tag] + line
            checked = True
            write_out(line)
        except:
            if len(line) > 6:
                checked = True
                write_out(line)

    if line:
        write_out(c)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        for filename in sys.argv[1:]:
            with file(filename, 'r') as fin:
                main(fin)
    else:
        main(sys.stdin)
