#!/bin/bash

source config.config

function add {
    # append normalized path to the watch
    realpath -m "$*" >> "$WATCHFILE"

    # delete duplicates
    sort < "$WATCHFILE" | uniq > "${WATCHFILE}.tmp" && mv "${WATCHFILE}.tmp" "$WATCHFILE"
}

function remove {
    local path
    path="$(realpath -m "$*")"

    # add a backslash before each slash
    path=$(echo "$path" | sed -e "s/\//\\\\\//g")
    sed -i "/$path/d" "$WATCHFILE"
}

function find_repos {
    local tempfile
    local lines
    local number

    tempfile=$(mktemp)

    echo "searching for repositories in $1..."
    echo ""

    # find all matches, number them, display and save to tmp without any buffering
    find "$1" -type "d" -name ".git" 2>/dev/null | \
    nl -n rn -w 5 -s ': ' | \
    stdbuf -o0 tee "$tempfile"

    lines=$(wc -l < "$tempfile")

    echo ""
    echo "Found $lines repositories in $1"
    echo ""

    echo "Enter the number of the repository to add (or press ENTER to end):"
    while true; do 
        echo -n "    > "
        
        read -r number

        if ! [[ "$number" =~ ^[0-9]+$ ]]; then
            break
        fi

        if [ "$number" -gt 0 ] && [ "$number" -le "$lines" ]; then
            local repo
            # get the nth line, delete the number, colon and space
            repo="$(head -n "$number" "$tempfile" | tail -n 1 | cut -d ':' -f 2 | cut -c 2-)"
            add "$repo"

            echo "Added $repo"
        else
            echo "Invalid number"
        fi
    done

    rm "$tempfile"
}

function clean_repos {
    # remove all non-existing directories
    cp "$WATCHFILE" "${WATCHFILE}.tmp"
    while read -r line; do
        if [ ! -d "$line" ]; then
            remove "$line"
        fi
    done < "${WATCHFILE}.tmp"
}