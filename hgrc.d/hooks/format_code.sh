#!/usr/bin/env bash

function log {
    echo $@ >&2
}

function background {
    $@
}

function find_tool {
    which "$1" || true
}

function format_file {
    TOOL=$(find_tool "$1")
    if [[ -z "$TOOL" ]]; then
	return 0
    fi
    shift
    background "$TOOL" "$@"
}

function cpp_format {
    format_file clang-format -i $1
}

function hack_format {
    format_file hackfmt -i $1
}

function python_format {
    # https://github.com/ambv/black
    format_file black $1
}

function buck_format {
    format_file buildifier -i $1
}

function format_all_code {
    rc=0
    files=$(hg status -n -m -a)
    for file in $files; do
	bname=$(basename $file)
	ext=${bname##*.}
	case $bname in
            BUCK|TARGETS)
		buck_format $file
		continue
		;;
	esac
	case $ext in
            c|cc|cpp|h|hh)
		cpp_format $file
		;;
            py)
		python_format $file
		;;
            php)
		# hack_format $file
		;;
	esac
    done

    files=$(hg status -n -m -a -r -d)
    if [[ "$files" == "" ]]; then
	rc=-1
    fi
    # done
    exit $rc
}

format_all_code
