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

TOTAL=0
NOT_FOUND=0
NOT_GIT=0
NO_REMOTE=0
UNCOMMITED=0
AHEAD=0
BEHIND=0
UP_TO_DATE=0

function report_single_repo {
    local path="$1"
    local is_silent="$2" #"true"/"false"
    
    TOTAL=$((TOTAL+1))
    # Check if the directory exists
    if [ ! -d "$path" ]; then
        if [ "$is_silent" = "false" ]; then
            echo "Error: Directory not found at '$path'."
        fi
        NOT_FOUND=$((NOT_FOUND+1))
        return 1
    fi

    # Navigate to the repository directory
    cd "$path/.." || return 1

    # Check if it's a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        if [ "$is_silent" = "false" ]; then
            echo "Error: '$path' is not a Git repository."
        fi
        NOT_GIT=$((NOT_GIT+1))
        return 1
    fi

    # Fetch latest changes from remote
    git fetch origin &>/dev/null

    # Gather information about the repository
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD (detached)")
    local remote=$(git config --get remote.origin.url)
    local has_uncommitted_changes=$(git status --porcelain)
    local behind=$(git rev-list --count HEAD..origin/$branch 2>/dev/null || echo 0)
    local ahead=$(git rev-list --count origin/$branch..HEAD 2>/dev/null || echo 0)

    # Update counters
    if [ -z "$remote" ]; then
        NO_REMOTE=$((NO_REMOTE+1))
    fi
    if [ -n "$has_uncommitted_changes" ]; then
        UNCOMMITED=$((UNCOMMITED+1))
    fi
    if [ "$ahead" -gt 0 ]; then
        AHEAD=$((AHEAD+1))
    fi
    if [ "$behind" -gt 0 ]; then
        BEHIND=$((BEHIND+1))
    fi
    if [ -n "$remote" ] && [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ] && [ -z "$has_uncommitted_changes" ]; then
        UP_TO_DATE=$((UP_TO_DATE+1))
    fi

    # Display information about the repository
    if [ "$is_silent" != "true" ]; then
        printf "%-20s %s\n" "Repository:" "$(pwd)"
        printf "%-20s %s\n" "Branch:" "$branch"
        printf "%-20s %s\n" "Remote:" "${remote:-No remote configured}"
        if [ -n "$has_uncommitted_changes" ]; then
            printf "%-20s %s\n" "Uncommited changes:" "Yes"
        else
            printf "%-20s %s\n" "Uncommited changes:" "No"
        fi
        printf "%-20s %s\n" "Ahead of remote:" "$ahead commits"
        printf "%-20s %s\n" "Behind remote:" "$behind commits"
    fi

    # Return to the original directory
    cd - >/dev/null || return 1
}

function summarize_counters_single {
    if [ $TOTAL -eq 0 ]; then
        echo "No repositories found."
        return
    fi

    if [ $NOT_FOUND -gt 0 ]; then
        echo "Repository not found."
        return
    fi

    if [ $NOT_GIT -gt 0 ]; then
        echo "Not a git repository. (Did you navigate to the /.git folder?)"
        return
    fi

    if [ $NO_REMOTE -gt 0 ]; then
        echo "No remote configured."
        return
    fi

    if [ $UNCOMMITED -gt 0 ]; then
        echo "The ropository has uncommited changes. "
    fi

    if [ $AHEAD -gt 0 ] && [ $BEHIND -gt 0 ]; then
        echo "The repository is both ahead of and behind the remote. "
        return
    fi
    
    if [ $AHEAD -gt 0 ]; then
        echo "The repository is ahead of the remote. "
        return
    fi

    if [ $BEHIND -gt 0 ]; then
        echo "The repository is behind the remote. "
        return
    fi

    if [ $UP_TO_DATE -gt 0 ]; then
        echo "The repository is up to date. "
        return
    fi
}

function summarize_counters_multiple {
    if [ $TOTAL -eq 0 ]; then
        echo "No repositories in the watchlist."
        return
    fi

    echo "Total repositories: $TOTAL"
    if [ $NOT_FOUND -gt 0 ]; then
        echo "Not found: $NOT_FOUND"
    fi
    if [ $NOT_GIT -gt 0 ]; then
        echo "Directories that are not git repositories: $NOT_GIT"
    fi
    if [ $NO_REMOTE -gt 0 ]; then
        echo "Repositories without remote configured: $NO_REMOTE"
    fi
    echo "Repositories up to date: $UP_TO_DATE"
    echo "Repositories with uncommited changes: $UNCOMMITED"
    echo "Repositories ahead of remote: $AHEAD"
    echo "Repositories behind remote: $BEHIND"

}

function report_watched {
    while read -r line; do
        report_single_repo "$line" "$1"
        if [ "$1" != "true" ]; then
            echo ""
        fi
    done < "$WATCHFILE"
}