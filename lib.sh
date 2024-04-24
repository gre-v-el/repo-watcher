#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 8 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 18 2024
# Version          : 0.1
#
# Description      :
# Library function for repowatch.
#
# Licensed under GPL

source config.config

function echoerr {
    >&2 echo "$@"
}

function check_command {
    if ! [ -x "$(command -v "$1")" ]; then
        echoerr "Error: $1 is not installed."
        exit 1
    fi
}

function add {
    # append normalized path to the watch
    realpath -m "$*" >> "$WATCHFILE"

    # delete duplicates
    sort < "$WATCHFILE" | uniq > "${WATCHFILE}.tmp" && mv "${WATCHFILE}.tmp" "$WATCHFILE"
}

function remove {
    local path
    path="$(realpath -m "$*")"

    # changes a slash (\/ = /) into a double backslash+slash (\\\\\/ = \\/)
    path=$(echo "$path" | sed -e "s/\//\\\\\//g") 
    # ...which is then escaped in the next sed into \/
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

    if [ "$lines" -eq 0 ]; then
        rm "$tempfile"
        return
    fi

    echo "Enter the index of the repository to add (leave blank to exit, enter \"ALL\" to add all):"
    while true; do 
        echo -n "    > "
        
        read -r number

        if [ "$number" = "ALL" ]; then
            while read -r line; do
                # delete the number, colon and space
                line=$(echo "$line" | cut -d ':' -f 2 | cut -c 2-)
                add "$line"
            done < "$tempfile"
            echo "Added all repositories"
            break
        fi

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
            echoerr "Invalid number"
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

    rm "${WATCHFILE}.tmp"

    echo "Removed $counter repos from the watchlist."
}

function wipe_repos {
    local answer
    echo -n "Do you want to remove all repositories from the watchlist? (y/N) >"
    read -r answer

    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        exit 0
    fi

    echo "Removed $(wc -l "$WATCHFILE" | cut -d ' ' -f 1) repos from the watchlist."
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
    if ! wget -q --spider "$PING_DOMAIN"; then
        echoerr "No internet connection"
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
            echoerr "Error: Directory not found at '$path'."
        fi
        NOT_FOUND=$((NOT_FOUND+1))
        return 1
    fi

    # Navigate to the repository directory
    cd "$path/.." || return 1

    # Check if it's a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        if [ "$is_silent" = "false" ]; then
            echoerr "Not a git repository. (Did you navigate to the /.git folder?)"
        fi
        NOT_GIT=$((NOT_GIT+1))
        return 1
    fi

    # Fetch latest changes from remote
    git fetch origin &>/dev/null

    # Gather information about the repository
    local branch
    local remote
    local has_uncommitted_changes
    local behind
    local ahead
    
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD (detached)")
    remote=$(git config --get remote.origin.url)
    has_uncommitted_changes=$(git status --porcelain)
    behind=$(git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)
    ahead=$(git rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo 0)

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

        if [ -n "$remote" ]; then
            printf "%-20s %s\n" "Ahead of remote:" "$ahead commits"
            printf "%-20s %s\n" "Behind remote:" "$behind commits"
        fi
    fi

    # Return to the original directory
    cd - >/dev/null || return 1
}

function summarize_counters_single {
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
    local iter=0
    local total
    total=$(wc -l < "$WATCHFILE")
    
    if [ "$total" -eq 0 ]; then
        return
    fi

    while read -r line; do
        if [ "$1" != "true" ]; then
            echo "[$((iter+1))/$total]"
        else
            echo -ne "[$((iter+1))/$total]\r"
        fi

        report_single_repo "$line" "$1"
        if [ "$1" != "true" ]; then
            echo ""
        fi

        iter=$((iter+1))
    done < "$WATCHFILE"
}

function resolve {
    local silent="$1" # "true"/"false"

    local total
    total="$(wc -l < "$WATCHFILE")"
    local iter=0

    local pushed=0
    local pulled=0

    while read -r line; do
        iter=$((iter+1))
        # counter
        if [ "$silent" = "true" ]; then
            echo -ne "[$iter/$total]\r"
        fi

        if ! [ -d "$line" ]; then
            if [ "$silent" != "true" ]; then
                echoerr "$line is inaccessible"
            fi
            cd - > /dev/null || return
            continue
        fi

        cd "$line/.." || return

        git fetch origin &>/dev/null

        local branch
        local has_uncommitted_changes
        local behind
        local ahead
        
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD (detached)")
        if [ "$branch" = "HEAD (detached)" ]; then
            if [ "$silent" != "true" ]; then
                echo "Skipping $line (detached HEAD)"
            fi
            cd - > /dev/null || return
            continue
        fi
        has_uncommitted_changes=$(git status --porcelain)
        behind=$(git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)
        ahead=$(git rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo 0)

        if [ -n "$has_uncommitted_changes" ]; then
            if [ "$silent" != "true" ]; then
                echo "Skipping $line (uncommited changes)"
            fi
            cd - > /dev/null || return
            continue
        fi

        if [ "$ahead" -eq 0 ] && [ "$behind" -gt 0 ]; then
            if [ "$silent" != "true" ]; then
                echo "Pulling $behind commits to $line"
            fi
            git pull origin "$branch" &>/dev/null
            pulled=$((pulled+1))
        fi

        if [ "$behind" -eq 0 ] && [ "$ahead" -gt 0 ]; then
            if [ "$silent" != "true" ]; then
                echo "Pushing $ahead commits in $line"
            fi
            git push origin "$branch" &>/dev/null
            pushed=$((pushed+1))
        fi

        cd - > /dev/null || return
    done < "$WATCHFILE"

    echo "Out of $total repositories:"
    echo "Pushed $pushed repositories"
    echo "Pulled $pulled repositories"
}

function notify {
    if ! wget -q --spider "$PING_DOMAIN" ; then
        if [ "$NOTIFY_OFFLINE" = "true" ]; then
            zenity --notification --text="Repowatch\nNo internet connection"
        fi
        exit 0
    fi

    report_watched "false" &>/dev/null

    local text="Up to date: $UP_TO_DATE\nAhead: $AHEAD\nBehind: $BEHIND"

    if [ "$NOT_FOUND" -gt 0 ]; then
        text="$text\nInaccessinble: $NOT_FOUND"
    fi

    zenity --notification --text="Repowatch\n$text"
}

function autoreport_get {
sudo -s <<'SUDO_END'
    source config.config

    read -r freq delay \
    < <(grep "$ANACRONTAB_JOB_ID" "$ANACRONTAB_CONFIG" \
    | sed -e "s/[ \t]\+/ /g" \
    | cut -d ' ' -f 1,2 )

    if [[ -z "$freq" ]] || [[ -z "$delay" ]]; then
        echo "Autoreport not set."
    else
        echo "Frequency: $freq days"
        echo "Delay: $delay minutes after startup"
    fi
SUDO_END
}

function autoreport_disable {
sudo -s <<'SUDO_END'
    source config.config

    temp=$(mktemp)

    grep -v "$ANACRONTAB_JOB_ID" "$ANACRONTAB_CONFIG" > "$temp"
    cp --preserve=mode "$temp" "$ANACRONTAB_CONFIG"
    rm "$temp"

SUDO_END
}

function autoreport_set {
    local freq="$1"
    local delay="$2"

sudo -s freq="$freq" delay="$delay" usr="$USER" id="$(id -u)" <<'SUDO_END'
    source lib.sh
    source config.config

    autoreport_disable

    echo "$freq $delay $ANACRONTAB_JOB_ID sudo -u $usr DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$id/bus /usr/local/bin/repowatch autoreport"  >> "$ANACRONTAB_CONFIG"

SUDO_END
}

function autoreport_perform {
    if [ "$AUTOSCAN_RESOLVE" = "true" ]; then
        resolve "true"
    fi

    notify
}

function show_gui {
    while true; do
        # clean and wipe are omitted (available as buttons in list)
        # TODO: wipe, clean, find
        local choice
        choice="$(zenity --width=550 --height=400 --list --title="Repowatch" --text="Choose an action" --column=Action Add Remove List Status Report Resolve Autoreport)"

        if [ $? -ne 0 ]; then # closed or cancelled
            exit
        fi

        case "$choice" in
            "Add")
                local path
                path="$(zenity --file-selection --directory --title="Select a git repository ")"
                
                if [ $? -ne 0 ]; then # closed or cancelled
                    continue
                fi
                
                path="$path/.git"
                if [ -d "$path" ] && [[ "$path" =~ \/\.git[\/]?$ ]]; then
                    add "$path"
                else
                    zenity --error --text="The repo does not exist or isn't a .git directory"
                fi
                ;;
            "Remove")
                local path
                while true; do
                    path="$(zenity --width=550 --height=400 --list --title="Repowatch" --text="Select a repository to remove" --column=Repository --separator="\n" < "$WATCHFILE")"
                    if [ $? -ne 0 ] || [ "$path" = "" ]; then # closed or cancelled
                        break
                    fi
                    remove "$path"
                done
                ;;
            "List")
                zenity --width=550 --height=400 --text-info --title="Repowatch" --filename="$WATCHFILE"
                ;;
            "Status")
                local path
                path="$(zenity --file-selection --directory --title="Select a git repository")"

                if [ $? -ne 0 ]; then # closed or cancelled
                    continue
                fi

                path="$path/.git"
                if [ -d "$path" ] && [[ "$path" =~ \/\.git[\/]?$ ]]; then
                    zenity --info --title="Repowatch" --text="$(repo_status "$path")"
                else
                    zenity --error --text="The repo does not exist or isn't a .git directory"
                fi
                ;;
            "Report")
                ( report_watched "false" 2>&1 ; summarize_counters_multiple ) | zenity --width=550 --height=400 --text-info --title="Repowatch"
                ;;
            "Resolve")
                resolve "false" | zenity --width=550 --height=400 --text-info --title="Repowatch"
                ;;
            "Autoreport")
                local choice2
                choice2="$(zenity --width=550 --height=400 --list --title="Repowatch" --text="Current settings:\n$(autoreport_get)" --column=Action Enable Disable Perform)"

                if [ $? -ne 0 ]; then # closed or cancelled
                    continue
                fi

                case "$choice2" in
                    "Enable")
                        local freq
                        local delay
                        
                        freq="$(zenity --entry --title="Repowatch" --text="Enter the frequency in days")"
                        delay="$(zenity --entry --title="Repowatch" --text="Enter the delay in minutes after startup")"
                        
                        if ! [[ "$freq" =~ ^[1-9][0-9]*$ ]] || ! [[ "$delay" =~ ^[1-9][0-9]*$ ]]; then
                            echoerr "Frequency and delay have to be whole numbers."
                        else
                            autoreport_set "$freq" "$delay"
                        fi
                        ;;
                    "Disable")
                        autoreport_disable
                        ;;
                    "Perform")
                        autoreport_perform
                        ;;
                esac
                ;;
        esac
    done
}