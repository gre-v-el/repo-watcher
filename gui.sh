#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 24 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 24 2024
# Version          : 1.0
#
# Description      :
# GUI functionality for repowatch.
#
# Licensed under GPL

source lib.sh

function show_gui {
    while true; do
        local choice
        choice="$(zenity --width=550 --height=400 --list --title="Repowatch" --text="Choose an action" --column=Action Add Remove List Status Find Report Resolve Autoreport Help)"

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
                    path="$(zenity --width=550 --height=400 --list --title="Repowatch" --text="Select a repository to remove" --column=Repository --separator="\n" < "$WATCHFILE" 2>/dev/null)"
                    if [ $? -ne 0 ] || [ "$path" = "" ]; then # closed or cancelled
                        break
                    fi
                    remove "$path"
                done
                ;;
            "List")
                local choice2
                choice2=$(zenity --width=550 --height=400 --text-info --title="Repowatch" --filename="$WATCHFILE" --extra-button="Wipe" --cancel-label="Back" --ok-label="Clean")
                local exit_code=$?
                if [ $exit_code -eq 1 ] && [ "$choice2" = "Wipe" ]; then
                    if zenity --question --title="Repowatch" --text="Do you want to remove all repositories from the watchlist?"; then
                        echo -n "" > "$WATCHFILE"
                    fi
                elif [ $exit_code -eq 0 ] && [ "$choice2" = "" ]; then
                    if zenity --question --title="Repowatch" --text="Do you want to remove all non-existing repositories from the watchlist?"; then
                        zenity --info --title="Repowatch" --text="$(clean_repos)"
                    fi
                fi
                
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
            "Find")
                local path
                path="$(zenity --file-selection --directory --title="Select a directory to search in")"

                if [ $? -ne 0 ] || [ "$path" = "" ]; then # closed or cancelled
                    continue
                fi

                if [ ! -d "$path" ]; then
                    zenity --error --text="This directory doesn't exist"
                    continue
                fi
        
                local tmp
                tmp=$(mktemp)
                echo -ne "Finding...\r"

                find "$path" -type "d" -name ".git" 2>/dev/null | \
                while read -r dir; do
                    if ! grep -qxF "$dir" "$WATCHFILE"; then
                        echo "$dir"
                    fi
                done >"$tmp"
                
                echo -ne "          \r"
                while true; do
                    local repo
                    repo=$(zenity --width=550 --height=400 --list --title="Repowatch" --text="Select repositories to add" --column=Repository --separator="\n" --extra-button="Add all" < "$tmp" 2>/dev/null)
                    local exit_code=$?

                    if [ $exit_code -eq 1 ] && [ "$repo" = "Add all" ]; then
                        while read -r repo; do
                            add "$repo"
                        done < "$tmp"
                        break
                    fi
                    
                    if [ $exit_code -ne 0 ] || [ "$repo" = "" ]; then # closed or cancelled
                        break
                    fi

                    add "$repo"
                    sed -i "\#$repo#d" "$tmp"
                done
                rm "$tmp"
                ;;
            "Report")
                ( report_watched "false" 2>&1 ; summarize_counters_multiple ) | zenity --width=550 --height=400 --text-info --title="Repowatch"
                ;;
            "Resolve")
                resolve "false" | zenity --width=550 --height=400 --text-info --title="Repowatch"
                ;;
            "Autoreport")
                local choice2

                while true; do
                    choice2="$(zenity --width=550 --height=400 --list --title="Repowatch" --text="Current settings:\n$(autoreport_get)" --column=Action Enable Disable Perform)" 2>/dev/null

                    if [ $? -ne 0 ]; then # closed or cancelled
                        break
                    fi

                    case "$choice2" in
                        "Enable")
                            local freq
                            local delay
                            
                            freq="$(zenity --entry --title="Repowatch" --text="Enter the frequency in days")"
                            delay="$(zenity --entry --title="Repowatch" --text="Enter the delay in minutes after startup")"
                            
                            if ! [[ "$freq" =~ ^[1-9][0-9]*$ ]] || ! [[ "$delay" =~ ^[1-9][0-9]*$ ]]; then
                                zenity --error --title="Repowatch" --text="Frequency and delay have to be whole numbers."
                            else
                                autoreport_set "$freq" "$delay"
                            fi
                            ;;
                        "Disable")
                            autoreport_disable
                            ;;
                        "Perform")
                            autoreport_perform &
                            zenity --info --title="Repowatch" --text="Scanning in the background. A notification will appear when done."
                            ;;
                    esac
                done
                ;;
            "Help")
                zenity --width=550 --height=400 --text-info --title="Repowatch" --filename="gui_help.msg"
                ;;
        esac
    done
}