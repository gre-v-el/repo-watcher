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
    local include_watched="$2"
    local tempfile
    local lines
    local number

    tempfile=$(mktemp)

    echo "searching for repositories in $1..."
    echo ""

    if [ "$include_watched" = "true" ]; then
        # find all matches, number them, display and save to tmp without any buffering
        find "$1" -type "d" -name ".git" 2>/dev/null | \
        nl -n rn -w 5 -s ': ' | \
        stdbuf -o0 tee "$tempfile"
    else
        # find all matches, filter them by watched, number them, display and save to tmp without any buffering
        find "$1" -type "d" -name ".git" 2>/dev/null | \
        while read -r dir; do
            if ! grep -qxF "$dir" "$WATCHFILE"; then
                echo "$dir"
            fi
        done | \
        nl -n rn -w 5 -s ': ' | \
        stdbuf -o0 tee "$tempfile"
    fi

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
    local counter=0
    # remove all non-existing directories
    cp "$WATCHFILE" "${WATCHFILE}.tmp"
    while read -r line; do
        if [ ! -d "$line" ]; then
            echo "removing $line"
            remove "$line"
            counter=$((counter+1))
        fi
    done < "${WATCHFILE}.tmp"

    mv "${WATCHFILE}.tmp" "$WATCHFILE" 

    echo "Removed $counter repos from the watchlist."
}

function wipe_repos {
    echo "Removed $(wc -l "$WATCHFILE") repos from the watchlist."
    echo -n "" > "$WATCHFILE"
}

function repo_status {
    local path
    path="$(realpath -m "$*")"

    if ! [ "$(grep -c "$path" "$WATCHFILE")" = "0" ]; then
        echo "This repository is watched."
    else
        echo "This repository is not watched."
    fi

    if [ -d "$path" ]; then
        echo "This repository is available."
    else
        echo "This repository is not available."
    fi
}

function check_internet {
    if ! wget -q --spider http://google.com; then
        echo "No internet connection"
        exit
    fi
}

# $1 - global path, $2 - is silent? "true"/"false" 
function report_single_repo {
    local path="$1"
    local is_silent="$2"
    
    # Check if the directory exists
    if [ ! -d "$path" ]; then
        echo "Error: Repository not found at '$path'."
        return 1
    fi

    # Navigate to the repository directory
    cd "$path/.." || return 1

    # Check if it's a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Error: '$path' is not a Git repository."
        return 1
    fi

    # Gather information about the repository
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD (detached)")
    local remote=$(git config --get remote.origin.url)
    local has_uncommitted_changes=$(git status --porcelain)
    local ahead=$(git rev-list --count --left-only HEAD...@{u} 2>/dev/null || echo 0)
    local behind=$(git rev-list --count --right-only HEAD...@{u} 2>/dev/null || echo 0)

    # Display information about the repository
    if [ "$is_silent" != "-s" ]; then
        echo "Repository: $(pwd)"
        echo "Branch: $branch"
        echo "Remote: ${remote:-No remote configured}"
        if [ -n "$has_uncommitted_changes" ]; then
            echo "Has uncommitted changes: Yes"
        else
            echo "Has uncommitted changes: No"
        fi
        echo "Ahead of remote: $ahead commits"
        echo "Behind remote: $behind commits"
    else
        # If silent mode is enabled, only display a summary
        echo "$(pwd): Branch - $branch, Ahead - $ahead, Behind - $behind"
    fi

    # Return to the original directory
    cd - >/dev/null || return 1
}

function report_watched {
    while read -r line; do
        report_single_repo "$line" "$1"
        echo ""
    done < "$WATCHFILE"
}