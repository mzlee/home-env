#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import subprocess
import sys
from datetime import datetime


def warn(msg):
    print("[powerline-bash]", msg)


KNOWN_MACHINES = {
    "mzlee-air.local": 232,
    "mzlee-mbp.local": 232,
    "mzlee-pro": 244,
}

SIGNALS_MAP = {
    1: "hup",
    2: "int",
    3: "quit",
    4: "ill",
    5: "trap",
    6: "abrt",
    7: "bus",
    8: "fpe",
    9: "kill",
    10: "usr1",
    11: "segv",
    12: "usr2",
    13: "pipe",
    14: "alrm",
    15: "term",
    17: "chld",
    18: "cont",
    19: "stop",
    20: "tstp",
    21: "ttin",
    22: "ttou",
    23: "urg",
    24: "xcpu",
    25: "xfsz",
    26: "vtalrm",
    27: "prof",
    28: "winch",
    29: "io",
    30: "pwr",
    31: "sys",
    34: "rtmin",
    64: "rtmax",
}


def Machine():
    uname = os.uname()
    bg = 232
    if uname[1] in KNOWN_MACHINES:
        bg = KNOWN_MACHINES[uname[1]]
    else:
        bg = hash(uname[1]) & 0xFF
    return uname, bg


class Color:
    # The following link is a pretty good resources for color values:
    # http://www.calmar.ws/vim/color-output.png

    HOST_NAME, HOST_PATH_BG = Machine()
    PATH_BG = 237  # dark grey
    PATH_FG = 250  # light grey
    CWD_FG = 254  # nearly-white grey
    SEPARATOR_FG = 244

    REPO_CLEAN_BG = 148  # a light green color
    REPO_CLEAN_FG = 0  # black
    REPO_DIRTY_BG = 161  # pink/red
    REPO_DIRTY_FG = 15  # white

    CMD_PASSED_BG = 236
    CMD_PASSED_FG = 15
    CMD_FAILED_BG = 161
    CMD_FAILED_FG = 15

    SVN_CHANGES_BG = 148
    SVN_CHANGES_FG = 22  # dark green

    VIRTUAL_ENV_FG = 226  # Maize and
    VIRTUAL_ENV_BG = 19  # Blue


class Powerline:
    symbols = {
        "compatible": {"separator": "\u25B6", "separator_thin": "\u276F"},
        "patched": {"separator": "\u25BA", "separator_thin": "\u25B8"},
    }

    color_templates = {"bash": "\\[\\e%s\\]", "zsh": "%%{%s%%}"}

    def __init__(self, mode, shell):
        self.shell = shell
        self.color_template = self.color_templates[shell]
        self.reset = self.color_template % "[0m"
        self.separator = Powerline.symbols[mode]["separator"]
        self.separator_thin = Powerline.symbols[mode]["separator_thin"]
        self.segments = []

    def color(self, prefix, code):
        return self.color_template % ("[%s;5;%sm" % (prefix, code))

    def fgcolor(self, code):
        return self.color("38", code)

    def bgcolor(self, code):
        return self.color("48", code)

    def append(self, segment):
        self.segments.append(segment)

    def draw(self):
        shifted = self.segments[1:] + [None]
        return (
            "".join((c.draw(n) for c, n in zip(self.segments, shifted))) + self.reset
        ).encode("utf-8")


class Segment:
    def __init__(self, powerline, content, fg, bg, separator=None, separator_fg=None):
        self.powerline = powerline
        self.content = content
        self.fg = fg
        self.bg = bg
        self.separator = separator or powerline.separator
        self.separator_fg = separator_fg or bg

    def draw(self, next_segment=None):
        if next_segment:
            separator_bg = self.powerline.bgcolor(next_segment.bg)
        else:
            separator_bg = self.powerline.reset

        return "".join(
            (
                self.powerline.fgcolor(self.fg),
                self.powerline.bgcolor(self.bg),
                self.content,
                separator_bg,
                self.powerline.fgcolor(self.separator_fg),
                self.separator,
            )
        )


def add_host_segment(powerline, hostname):
    if hostname not in KNOWN_MACHINES:
        powerline.append(
            Segment(
                powerline, " %s " % hostname, Color.PATH_FG, Color.HOST_PATH_BG ^ 255
            )
        )


def add_cwd_segment(powerline, cwd, maxdepth, cwd_only=False):
    # powerline.append(' \\w ', 15, 237)
    home = os.getenv("HOME")
    cwd = cwd or os.getenv("PWD")

    if cwd.find(home) == 0:
        cwd = cwd.replace(home, "~", 1)

    if cwd[0] == "/":
        cwd = cwd[1:]

    names = cwd.split("/")
    if len(names) > maxdepth:
        names = names[:2] + ["\u2026"] + names[2 - maxdepth :]

    if not cwd_only:
        powerline.append(
            Segment(
                powerline,
                " %s " % names.pop(0),
                Color.PATH_FG,
                Color.HOST_PATH_BG,
                powerline.separator_thin,
                Color.SEPARATOR_FG,
            )
        )
        for n in names[:-1]:
            powerline.append(
                Segment(
                    powerline,
                    " %s " % n,
                    Color.PATH_FG,
                    Color.PATH_BG,
                    powerline.separator_thin,
                    Color.SEPARATOR_FG,
                )
            )
    if len(names):
        powerline.append(
            Segment(powerline, " %s " % names[-1], Color.CWD_FG, Color.PATH_BG)
        )


def get_hg_status():
    has_modified_files = False
    has_untracked_files = False
    has_missing_files = False
    output = subprocess.Popen(["hg", "status"], stdout=subprocess.PIPE).communicate()[0]
    for line in output.split("\n"):
        if line == "":
            continue
        elif line[0] == "?":
            has_untracked_files = True
        elif line[0] == "!":
            has_missing_files = True
        else:
            has_modified_files = True
    return has_modified_files, has_untracked_files, has_missing_files


def add_hg_segment(powerline, cwd):
    branch = os.popen("hg branch 2> /dev/null").read().rstrip()
    if len(branch) == 0:
        return False
    bg = Color.REPO_CLEAN_BG
    fg = Color.REPO_CLEAN_FG
    has_modified_files, has_untracked_files, has_missing_files = get_hg_status()
    if has_modified_files or has_untracked_files or has_missing_files:
        bg = Color.REPO_DIRTY_BG
        fg = Color.REPO_DIRTY_FG
        extra = ""
        if has_untracked_files:
            extra += "+"
        if has_missing_files:
            extra += "!"
        branch += " " + extra if extra != "" else ""
    powerline.append(Segment(powerline, " %s " % branch, fg, bg))
    return True


def add_current_time_segment(powerline):
    now = datetime.now()
    powerline.append(
        Segment(
            powerline,
            " %s " % now.strftime("%D"),
            Color.PATH_BG,
            Color.HOST_PATH_BG ^ 32,
            ":",
        )
    )
    powerline.append(
        Segment(
            powerline,
            " %s " % now.strftime("%H:%M:%S"),
            Color.PATH_FG,
            Color.HOST_PATH_BG ^ 32,
        )
    )
    return True


def get_git_version():
    output = os.getenv("GIT_VERSION")
    if output is None:
        output = subprocess.Popen(
            ["git", "version"], stdout=subprocess.PIPE
        ).communicate()[0]
    GIT_VERSION = tuple([int(x) for x in output.split()[2].split(".")])
    return GIT_VERSION


def prefix_dir(cwd):
    dirs = os.getenv("BLACKLIST_DIRS")
    if dirs is None:
        return False
    for d in dirs.split(":"):
        if cwd.startswith(d):
            return True
    return False


def get_git_status():
    has_pending_commits = True
    has_untracked_files = False
    origin_position = ""
    if get_git_version() < (1, 7, 0, 5):
        GIT_STATUS = ["git", "status"]
    else:
        GIT_STATUS = ["git", "status", "--ignore-submodules"]
    output = subprocess.Popen(GIT_STATUS, stdout=subprocess.PIPE).communicate()[0]
    for line in output.split("\n"):
        origin_status = re.findall(r"Your branch is (ahead|behind).*?(\d+) comm", line)
        if origin_status:
            origin_position = " %d" % int(origin_status[0][1])
            if origin_status[0][0] == "behind":
                origin_position += "\u21E3"
            if origin_status[0][0] == "ahead":
                origin_position += "\u21E1"

        if line.find("nothing to commit") >= 0:
            has_pending_commits = False
        if line.find("Untracked files") >= 0:
            has_untracked_files = True
    return has_pending_commits, has_untracked_files, origin_position


def add_git_segment(powerline, cwd):
    # cmd = "git branch 2> /dev/null | grep -e '\\*'"
    cwd = os.getcwd()
    bg = Color.REPO_CLEAN_BG
    fg = Color.REPO_CLEAN_FG
    if prefix_dir(cwd):
        powerline.append(Segment(powerline, " git ", fg, bg))
        return True
    p1 = subprocess.Popen(
        ["git", "branch"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    p2 = subprocess.Popen(
        ["grep", "-e", "\\*"], stdin=p1.stdout, stdout=subprocess.PIPE
    )
    output = p2.communicate()[0].strip()
    if not output:
        return False

    branch = output.rstrip()[2:]
    has_pending_commits, has_untracked_files, origin_position = get_git_status()
    branch += origin_position
    if has_untracked_files:
        branch += " +"

    if has_pending_commits:
        bg = Color.REPO_DIRTY_BG
        fg = Color.REPO_DIRTY_FG

    powerline.append(Segment(powerline, " %s " % branch, fg, bg))
    return True


def add_svn_segment(powerline, cwd):
    if not os.path.exists(os.path.join(cwd, ".svn")):
        return
    """svn info:
        First column: Says if item was added, deleted, or otherwise changed
        ' ' no modifications
        'A' Added
        'C' Conflicted
        'D' Deleted
        'I' Ignored
        'M' Modified
        'R' Replaced
        'X' an unversioned directory created by an externals definition
        '?' item is not under version control
        '!' item is missing (removed by non-svn command) or incomplete
        '~' versioned item obstructed by some item of a different kind
    """
    # TODO: Color segment based on above status codes
    try:
        # cmd = '"svn status | grep -c "^[ACDIMRX\\!\\~]"'
        p1 = subprocess.Popen(
            ["svn", "status"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        p2 = subprocess.Popen(
            ["grep", "-c", "^[ACDIMRX\\!\\~]"], stdin=p1.stdout, stdout=subprocess.PIPE
        )
        output = p2.communicate()[0].strip()
        repo_string = " svn "
        if len(output) > 0 and int(output) > 0:
            changes = output.strip()
            repo_string += "%s " % changes
        powerline.append(
            Segment(powerline, repo_string, Color.SVN_CHANGES_FG, Color.SVN_CHANGES_BG)
        )
    except OSError:
        return False
    except subprocess.CalledProcessError:
        return False
    return True


def add_repo_segment(powerline, cwd):
    for add_repo_segment in (add_git_segment, add_svn_segment, add_hg_segment):
        try:
            if add_repo_segment(p, cwd):
                return
        except subprocess.CalledProcessError:
            pass
        except OSError:
            pass


def add_lw_repo_segment(powerline, branch):
    if branch:
        branch = branch.strip()[1:-1]
        bg = Color.REPO_CLEAN_BG
        fg = Color.REPO_CLEAN_FG
        powerline.append(Segment(powerline, " %s " % branch, fg, bg))


def add_virtual_env_segment(powerline, cwd):
    env = os.getenv("VIRTUAL_ENV")
    if env is None:
        return False

    env_name = os.path.basename(env)
    bg = Color.VIRTUAL_ENV_BG
    fg = Color.VIRTUAL_ENV_FG
    powerline.append(Segment(powerline, " %s " % env_name, fg, bg))
    return True


def add_root_indicator(powerline, error):
    bg = Color.CMD_PASSED_BG
    fg = Color.CMD_PASSED_FG
    err = int(error)
    if err != 0:
        fg = Color.CMD_FAILED_FG
        bg = Color.CMD_FAILED_BG
    powerline.append(Segment(powerline, " \\$ ", fg, bg))
    if err > 128 and (err - 128) in SIGNALS_MAP:
        powerline.append(
            Segment(powerline, " [%s] " % SIGNALS_MAP[err - 128], Color.PATH_FG, bg)
        )


def get_valid_cwd():
    """We check if the current working directory is valid or not. Typically
    happens when you checkout a different branch on git that doesn't have
    this directory.
    We return the original cwd because the shell still considers that to be
    the working directory, so returning our guess will confuse people
    """
    try:
        cwd = os.getenv("PWD")  # This is where the OS thinks we are
    except:
        cwd = os.getenv("PWD")  # This is where the OS thinks we are
        parts = cwd.split(os.sep)
        up = cwd
        while parts and not os.path.exists(up):
            parts.pop()
            up = os.sep.join(parts)
        try:
            os.chdir(up)
        except:
            warn("Your current directory is invalid.")
            sys.exit(1)
        warn("Your current directory is invalid. Lowest valid directory: " + up)
    return cwd


if __name__ == "__main__":
    try:
        import argparse

        arg_parser = argparse.ArgumentParser()
        arg_parser.add_argument("--cwd-only", action="store_true")
        arg_parser.add_argument("--mode", action="store", default="patched")
        arg_parser.add_argument("--shell", action="store", default="bash")
        arg_parser.add_argument("--error", action="store", default=0)
        arg_parser.add_argument("--branch", action="store", default="")
        args = arg_parser.parse_args()
    except:

        class DummyArgs(object):
            def __init__(self):
                self.mode = "compatible"
                self.shell = "bash"
                self.cwd_only = False
                self.error = 0
                self.branch = ""

        args = DummyArgs()

    p = Powerline(mode=args.mode, shell=args.shell)
    cwd = get_valid_cwd()
    add_current_time_segment(p)
    if Color.HOST_NAME[0] == "Linux":
        add_host_segment(p, Color.HOST_NAME[1])
    add_virtual_env_segment(p, cwd)
    # p.append(Segment(p, ' \\u ', 250, 240))
    # p.append(Segment(p, ' \\h ', 250, 238))
    add_cwd_segment(p, cwd, 5, args.cwd_only)
    add_lw_repo_segment(p, args.branch)
    # add_repo_segment(p, cwd)
    add_root_indicator(p, args.error)
    sys.stdout.buffer.write(p.draw())

# vim: set expandtab:
