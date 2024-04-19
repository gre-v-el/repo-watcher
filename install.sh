#!/bin/bash

# Author           : Gabriel Myszkier
# Created On       : Apr 15 2024
# Last Modified By : Gabriel Myszkier
# Last Modified On : Apr 18 2024
# Version          : 0.1
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
  echoerr 'Error: git is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v zenity)" ]; then
  echoerr 'Error: zenity is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v anacron)" ]; then
  echoerr 'Error: anacron is not installed.' >&2
  exit 1
fi

# cd into the script's directory
cd "$(realpath "$(dirname "$0")")" || exit 1

# make scripts executable
chmod a+x repowatch.sh
chmod a+x lib.sh

# check access to /usr/local/bin
if [ ! -w "/usr/local/bin" ]; then
  echoerr 'Error: /usr/local/bin is not writable. Run with sudo.' >&2
  exit 1
fi

# add a repowatch script to the user's bin directory
cat <<CAT_END > "/usr/local/bin/repowatch"
#!/bin/bash

cd "$(realpath "$(dirname "$0")")"

"./repowatch.sh" "\$@"
CAT_END

# make the script executable
chmod a+x /usr/local/bin/repowatch