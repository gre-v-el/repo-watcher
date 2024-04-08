#!/bin/bash

source lib.sh

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Placeholder usage"
    exit
fi

if [ "$1" = "add" ] && [ $# -eq 2 ]; then
    if [ -d "$2" ] && [[ "$2" =~ \/\.git$ ]]; then
        add "$2"
    else
        echo "The file does not exist or isn't a .git directory"
    fi

else
    echo "Invalid usage. See $0 --help"
fi