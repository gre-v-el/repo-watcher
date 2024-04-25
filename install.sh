#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 15 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 23 2024
# Version          : 1.0
#
# Description      :
# Installation script for repowatch.
#
# Licensed under GPL

function echoerr {
    >&2 echo "$@"
}

# check dependencies
if ! [ -x "$(command -v git)" ]; then
  echoerr 'Error: git is not installed.'
  exit 1
fi

if ! [ -x "$(command -v zenity)" ]; then
  echo 'Warning: zenity is not installed. Notifications and gui will not work.'
fi

if ! [ -x "$(command -v anacron)" ]; then
  echo 'Warning: anacron is not installed. You will not be able to set autoreport.'
fi

# check if already installed
if [ -f "/usr/local/bin/repowatch" ]; then
  echoerr 'Error: repowatch is already installed.'
  exit 1
fi

# cd into the script's directory
cd "$(realpath "$(dirname "$0")")" || exit 1

# check access to /usr/local/bin
if [ ! -w "/usr/local/bin" ]; then
  echoerr 'Error: /usr/local/bin is not writable. Run with sudo.' >&2
  exit 1
fi

# make scripts executable
chmod a+x repowatch.sh
chmod a+x lib.sh
chmod a+x gui.sh

# add a repowatch script to the user's bin directory
cat <<CAT_END > "/usr/local/bin/repowatch"
#!/bin/bash

cd "$(realpath ".")"

"./repowatch.sh" "\$@"
CAT_END

# make the script executable
chmod a+x /usr/local/bin/repowatch