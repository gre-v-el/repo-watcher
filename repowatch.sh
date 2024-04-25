#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 8 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 24 2024
# Version          : 1.0
#
# Description      :
# CLI entry point for repowatch.
#
# Licensed under GPL

source lib.sh
source gui.sh

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat help.msg
    exit
elif [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
    echo "repowatch 1.0"
    echo "written by Gabriel Myszkier"
    echo "Licensed under GPL"
    echo ""
    echo "see $(realpath "$(dirname "$0")")/README.md"
    echo "see https://github.com/gre-v-el/repo-watcher"
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
    check_command "git"
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
    check_command "git"
    check_internet
    report_watched "false"
    summarize_counters_multiple
# REPORT WATCHED (SUMMARIZE)
elif [ "$1" = "report" ] && [ $# -eq 2 ] && [ "$2" = "-s" ]; then
    check_command "git"
    check_internet
    report_watched "true"
    summarize_counters_multiple
# REPORT GIVEN
elif [ "$1" = "report" ] && [ $# -eq 2 ]; then
    check_command "git"
    check_internet
    report_single_repo "$(realpath "$2")" "false"
# REPORT GIVEN (SUMMARIZE)
elif [ "$1" = "report" ] && [ $# -eq 3 ] && [ "$3" = "-s" ]; then
    check_command "git"
    check_internet
    report_single_repo "$(realpath "$2")" "true"
    summarize_counters_single
# RESOLVE
elif [ "$1" = "resolve" ] && [ $# -eq 1 ]; then
    check_command "git"
    check_internet
    resolve "false"
# RESOLVE (SUMMARIZE)
elif [ "$1" = "resolve" ] && [ $# -eq 2 ] && [ "$2" = "-s" ]; then
    check_command "git"
    check_internet
    resolve "true"
# AUTOREPORT
elif [ "$1" = "autoreport" ] && [ $# -eq 1 ]; then
    check_command "zenity"
    check_command "git"
    autoreport_perform
elif [ "$1" = "autoreport" ] && [ $# -eq 2 ] && [ "$2" = "-l" ]; then
    check_command "anacron"
    autoreport_get
# AUTOREPORT (disable)
elif [ "$1" = "autoreport" ] && [ $# -eq 2 ] && [ "$2" = "-d" ]; then
    check_command "anacron"
    autoreport_disable
# AUTOREPORT (SET)
elif [ "$1" = "autoreport" ] && [ $# -eq 4 ] && [ "$2" = "-s" ]; then
    check_command "git"
    check_command "anacron"
    check_command "zenity"
    if ! [[ "$3" =~ ^[1-9][0-9]*$ ]] || ! [[ "$4" =~ ^[1-9][0-9]*$ ]]; then
        echoerr "Frequency and delay have to be whole numbers."
    else
        autoreport_set "$3" "$4"
    fi
# NOTIFY
elif [ "$1" = "notify" ] && [ $# -eq 1 ]; then
    check_command "zenity"
    notify
# GUI
elif [ "$1" = "gui" ] && [ $# -eq 1 ]; then
    check_command "git"
    check_command "anacron"
    check_command "zenity"
    show_gui
# INVALID USAGE
else
    echoerr "Invalid usage. See $0 --help"
fi