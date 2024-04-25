#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 15 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 23 2024
# Version          : 1.0
#
# Description      :
# Uninstallation script for repowatch.
#
# Licensed under GPL

function echoerr {
    >&2 echo "$@"
}

# check if repowatch is installed
if [ ! -f "/usr/local/bin/repowatch" ]; then
  echoerr 'Error: repowatch is not installed.'
  exit 1
fi

# check access to /usr/local/bin
if [ ! -w "/usr/local/bin" ]; then
  echoerr 'Error: /usr/local/bin is not writable. Run with sudo.' >&2
  exit 1
fi

# delete the anacron job if it exists
if ! repowatch autoreport -d &>/dev/null; then
  echoerr 'Error: Failed to delete anacron job. Did not uninstall.'
  exit 1
fi

# remove the script
rm /usr/local/bin/repowatch

echo 'Repowatch uninstalled successfully. You can now safely delete this directory.'