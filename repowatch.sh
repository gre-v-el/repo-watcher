#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 8 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 18 2024
# Version          : 0.1
#
# Description      :
# CLI entry point for repowatch.
#
# Licensed under GPL

source lib.sh

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat help.msg
    exit
fi

# ADD
if [ "$1" = "add" ] && [ $# -eq 2 ]; then
    if [ -d "$2" ] && [[ "$2" =~ \/\.git[\/]?$ ]]; then
        add "$2"
    else
        echoerr "The repo does not exist or isn't a .git directory"
    fi
# REMOVE
elif [ "$1" = "rm" ] && [ $# -eq 2 ]; then
    remove "$2"
# LIST
elif [ "$1" = "list" ] && [ $# -eq 1 ]; then
    cat "$WATCHFILE"
# STATUS
elif [ "$1" = "status" ] && [ $# -eq 2 ]; then
    if [[ "$2" =~ \/\.git[\/]?$ ]]; then
        repo_status "$2"
    else
        echoerr "This is not a .git directory"
    fi
# CLEAN
elif [ "$1" = "clean" ] && [ $# -eq 1 ]; then
    clean_repos
# WIPE
elif [ "$1" = "wipe" ] && [ $# -eq 1 ]; then
    wipe_repos
# FIND (OMIT)
elif [ "$1" = "find" ] && [ $# -eq 2 ]; then
    if [ -d "$2" ]; then
        find_repos "$2" "false"
    else
        echoerr "This directory doesn't exist"    
    fi
# FIND (INCLUDE)
elif [ "$1" = "find" ] && [ $# -eq 3 ] && [ "$3" = "-w" ]; then
    if [ -d "$2" ]; then
        find_repos "$2" "true"
    else
        echoerr "This directory doesn't exist"    
    fi
# REPORT WATCHED
elif [ "$1" = "report" ] && [ $# -eq 1 ]; then
    check_internet
    report_watched "false"
    summarize_counters_multiple
# REPORT WATCHED (SILENT)
elif [ "$1" = "report" ] && [ $# -eq 2 ] && [ "$2" = "-s" ]; then
    check_internet
    report_watched "true"
    summarize_counters_multiple
# REPORT GIVEN
elif [ "$1" = "report" ] && [ $# -eq 2 ]; then
    check_internet
    report_single_repo "$(realpath "$2")" "false"
# REPORT GIVEN (SILENT)
elif [ "$1" = "report" ] && [ $# -eq 3 ] && [ "$3" = "-s" ]; then
    check_internet
    report_single_repo "$(realpath "$2")" "true"
    summarize_counters_single
# RESOLVE
elif [ "$1" = "resolve" ] && [ $# -eq 1 ]; then
    check_internet
    resolve "false"
# RESOLVE (SILENT)
elif [ "$1" = "resolve" ] && [ $# -eq 2 ] && [ "$2" = "-s" ]; then
    check_internet
    resolve "true"
# AUTOREPORT
elif [ "$1" = "autoreport" ] && [ $# -eq 1 ]; then
    autoreport_perform
elif [ "$1" = "autoreport" ] && [ $# -eq 2 ] && [ "$2" = "-l" ]; then
    autoreport_get
# AUTOREPORT (disable)
elif [ "$1" = "autoreport" ] && [ $# -eq 2 ] && [ "$2" = "-d" ]; then
    autoreport_disable
# AUTOREPORT (SET)
elif [ "$1" = "autoreport" ] && [ $# -eq 4 ] && [ "$2" = "-s" ]; then
    if ! [[ "$3" =~ ^[1-9][0-9]*$ ]] || ! [[ "$4" =~ ^[1-9][0-9]*$ ]]; then
        echoerr "Frequency and delay have to be whole numbers."
    else
        autoreport_set "$3" "$4"
    fi
# NOTIFY
elif [ "$1" = "notify" ] && [ $# -eq 1 ]; then
    notify
# INVALID USAGE
else
    echoerr "Invalid usage. See $0 --help"
fi