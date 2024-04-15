#!/bin/bash

# check dependencies
if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v zenity)" ]; then
  echo 'Error: zenity is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v anacron)" ]; then
  echo 'Error: anacron is not installed.' >&2
  exit 1
fi

# make scripts executable
chmod a+x repowatch.sh
chmod a+x lib.sh

# check access to /usr/local/bin
if [ ! -w "/usr/local/bin" ]; then
  echo 'Error: /usr/local/bin is not writable. Run with sudo.' >&2
  exit 1
fi

# add a repowatch script to the user's bin directory
cat <<CAT_END > "/usr/local/bin/repowatch"
#!/bin/bash

"$(realpath "$(dirname "$0")")/repowatch.sh" "\$@"
CAT_END

# make the script executable
chmod a+x /usr/local/bin/repowatch