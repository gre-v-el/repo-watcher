#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 8 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 10 2024
# Version          : 0.1
#
# Description      :
# Watch your git repositories for changes (entry point - CLI)
#
# Licensed under GPL


source lib.sh

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Placeholder usage"
    exit
fi

# ADD
if [ "$1" = "add" ] && [ $# -eq 2 ]; then
    if [ -d "$2" ] && [[ "$2" =~ \/\.git$ ]]; then
        add "$2"
    else
        echo "The repo does not exist or isn't a .git directory"
    fi
# REMOVE
elif [ "$1" = "rm" ] && [ $# -eq 2 ]; then
    remove "$2"
# LIST
elif [ "$1" = "list" ] && [ $# -eq 1 ]; then
    cat "$WATCHFILE"
# STATUS
elif [ "$1" = "status" ] && [ $# -eq 2 ]; then
    if [[ "$2" =~ \/\.git$ ]]; then
        repo_status "$2"
    else
        echo "The repo does not exist or isn't a .git directory"
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
        echo "This directory doesn't exist"    
    fi
# FIND (INCLUDE)
elif [ "$1" = "find" ] && [ $# -eq 3 ] && [ "$3" = "-w" ]; then
    if [ -d "$2" ]; then
        find_repos "$2" "true"
    else
        echo "This directory doesn't exist"    
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
# APPLY
elif [ "$1" = "apply" ] && [ $# -eq 1 ]; then
    check_internet
    apply
# INVALID USAGE
else
    echo "Invalid usage. See $0 --help"
fi