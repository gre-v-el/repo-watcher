#!/bin/bash

source config.config

function add {
    # append normalized path to the watch
    realpath "$*" >> "$WATCHFILE"

    # delete duplicates
    sort < "$WATCHFILE" | uniq > "${WATCHFILE}.tmp" && mv "${WATCHFILE}.tmp" "$WATCHFILE"
}

function remove {
    local path
    path="$(realpath "$*")"

    # add a backslash before each slash
    path=$(echo "$path" | sed -e "s/\//\\\\\//g")
    sed -i "/$path/d" "$WATCHFILE"
}

function find_repos {
    local tempfile
    tempfile=$(mktemp)

    # find all matches, number them, display and save to tmp without any buffering
    find "$1" -type "d" -name ".git" 2>/dev/null | \
    nl -n rn -w 5 -s ': ' | \
    stdbuf -o0 tee "$tempfile"

    rm "$tempfile"
}