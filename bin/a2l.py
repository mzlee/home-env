#!/usr/bin/python
import os
import re
import sys
import subprocess
import getopt

def usage():
    print """usage: %s <address>
Translate the hex address into a line in the binary
""" % sys.argv[0].split("/")[-1]
    print """Flags:
-b [binary|a.out]     The binary to scan. Defaults to a.out
-h                    Print this help
-l [lines|10]         The number of lines to output per address. Defaults to 10 above and 10 below the address
-o [output|stdout]    The name of the output file. Defaults to stdout
"""

def parseInt(s):
    if s.startswith("0x"):
        return int(s, 16)
    if s.startswith("0"):
        return int(s, 8)
    return int(s)

def decomposeObject(binary, addr, width=10, out=sys.stdout):
    if not os.path.isfile(binary):
        sys.stderr.write("Error: %s not found", binary)
        usage()
        sys.exit(1)

    a2l = subprocess.Popen(["addr2line", "-e", binary, "-if", "%x" % addr], stdout=subprocess.PIPE)
    od = subprocess.Popen(["objdump", "-l", "-d", "--start-address=0x%x" % (addr - 128), "--stop-address=0x%x" % (addr + 128), binary], stdout=subprocess.PIPE)
    fn, codeLine = [l.strip() for l in a2l.stdout.readlines()]
    lines = od.stdout.readlines()

    lineNum = 0
    output = []
    inFunction = False
    out.write("Function: %s\n" % fn)
    out.write("Code Line: %s\n" % codeLine)
    out.write(''.join(['-']*(len(codeLine) + 11)) + '\n')

    for line in lines:
        line = line.strip()
        if re.match("\d* <.*>", line):
            inFunction = False
        if re.match("\d* <%s>" % fn, line):
            inFunction = True
        elif inFunction:
            output.append(line)
            if codeLine == line:
                lineNum = len(output)

    start = max(lineNum - width, 0)
    end = min(start + 2*width, len(output))
    for l in output[start:end]:
        out.write("%s\n" % l)

if __name__ == "__main__":
    conf = {}
    opt, args = getopt.getopt(sys.argv[1:], "b:ho:w:")
    for o, a in opt:
        if o in ['-b']:
            conf['binary'] = a
        elif o in ['-h']:
            usage()
            sys.exit(0)
        elif o in ['-o']:
            conf['out'] = open(a, 'w')
        elif o in ['-w']:
            conf['width'] = int(a)

    if 'binary' not in conf:
        conf['binary'] = "a.out"

    if len(args) == 0:
        usage()
        sys.exit(-1)
    conf['addr'] = int(args[0].strip(), 16)
    decomposeObject(**conf)

    if 'out' in conf:
        conf['out'].close()
