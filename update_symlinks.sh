#!/usr/bin/env bash
set -e

if [ -L "previous" ]
then
    previous_target=$(readlink "previous")
    if [ -z "$previous_target" ]
    then
        echo "Error: Target for symbolic link 'previous' is empty."
        exit 1
    elif [ ! -d "$previous_target" ]
    then
        echo "Error: Target directory for symbolic link 'previous' does not exist: $previous_target"
        exit 1
    else
        rm "previous"
        echo "Removed 'previous' symbolic link."
    fi
else
    echo "Symbolic link 'previous' does not exist."
fi

if [ -d "current" ]
then
    if [ -L "current" ]
    then
        current_target=$(readlink "current")
        if [ -z "$current_target" ]
        then
            echo "Error: Target for symbolic link 'current' is empty."
            exit 1
        elif [ ! -d "$current_target" ]
        then
            echo "Error: Target directory for symbolic link 'current' does not exist: $current_target"
            exit 1
        else
            ln -s "$current_target" "previous"
            echo "Created 'previous' symbolic link."
        fi
    fi
else
    echo "Directory 'current' does not exist."
fi
