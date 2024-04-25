# repowatch - A tool to manage local git repositories

You can search for repositories, watch them, see reports, and configure automatic push/pull resolution. The tool is designed to be used in the terminal, but it also has a graphical interface. It also supports periodic desktop notifications.

# Installation

Repowatch depends on **Zenity** to show the gui and notifications, and **anacron** to perform automatic checks. You can still use the tool without these dependencies, but you won't be able to use the GUI or automatic checks. The installation script will install the program to `/usr/local/bin/repowatch`.

1. Clone the repository and don't move it (after the installation the script will depend on this folder).
2. Run the `install.sh` script.

```bash
$ git clone https://github.com/gre-v-el/repo-watcher.git
$ cd repo-watcher
$ sudo ./install.sh
```

# Usage
usage: `repowatch [--help|--version] <command> [<args>]`

### Commands:
* `add <.git directory path>` 
  
    Add a repository to the watchlist
* `rm <.git directory path>`

    Remove a repository from the watchlist
* `list`

    Display all watched repositories
* `status <.git directory path>`

    Show the status of a given repository (watched, available)
* `clean`

    Remove all unavailable repositories (deleted, without permissions, unmounted)
* `wipe`

    Remove all repositories from the list
* `find <directory> [-w]`

    Find all repositories in a given directory. By default, it omits already watched repositories. The `-w` flag includes watched repositories.
* `report [<.git directory path>] [-s]`

    If given a path, it reports the state of this repository. Otherwise, it reports the state of all watched repositories. The -s flag tells the program to summarize the report without details.
* `resolve [-s]`

    Resolve all trivial cases (only push or only pull). The -s flag tells the program to summarize the report without details.
* `autoreport [-l] [-d] [-s <frequency> <delay>]`

    Manage the frequency of background checks. `-l` flag outputs the current configuration. `-d` flag disables autoreport. `-s` flag sets a new configuration. `Frequency` is a period in days, `delay` is the delay in minutes after the system startup after which the check should be run. If no flags have been given, an actual check will be performed. Each check will send a desktop notification. Requires sudo to read and write to anacron config.
* `notify`

    Report watched repositories as a notification. This is what autoreport looks like.
* `gui`

    Launch a Zenity-based graphical user interface.

### See `config.config` for additional configuration:
* `WATCHFILE`

    A file to store watched repositories.
* `AUTOSCAN_RESOLVE`

    Whether or not the autoscan should resolve trivial cases.
* `NOTIFY_OFFLINE`

    Whether or not the autoscan should send a notification when you're offline.
* `PING_DOMAIN`

    A domain the program will ping to check if you're online.

### Comments

**"Trivial cases"** do not require merging or committing. Examples:
* Your local repository is ahead of the remote repository, and there are no new changes on the remote to pull. There are no uncommitted changes.
* There are new commits on the remote, and there are no new commits or uncommitted changes in your local repository.

The **.git directory path** is a path to the .git directory inside your repository, for example `/home/usr/repo/.git`. The paths can be both global and local.

# Examples

```
$ repowatch status /home/usr/repo/.git
This repository is not watched.
This repository is available.

$ repowatch add /home/usr/repo/.git

$ repowatch list
/home/usr/repo/.git

$ repowatch status /home/usr/repo/.git
This repository is watched.
This repository is available.
```

```
$ repowatch find /home/usr
     1: /home/usr/otherrepo1/.git
     2: /home/usr/otherrepo2/.git

Found 2 repositories in /home/usr/

Enter the index of the repository to add (or press ENTER to end):
    > 1
Added /home/usr/otherrepo1/.git
    > [Enter]

$ repowatch list
/home/usr/repo/.git
/home/usr/otherrepo1/.git
```

```
$ repowatch report

[1/2]
Repository:          /home/usr/repo/.git
Branch:              main
Remote:              https://remote.com/repo.git
Uncommited changes:  Yes
Ahead of remote:     1 commits
Behind remote:       2 commits

[2/2]
Repository:          /home/usr/otherrepo1/.git
Branch:              main
Remote:              No remote configured
Uncommited changes:  Yes

Total repositories: 2
Repositories without remote configured: 1
Repositories up to date: 0
Repositories with uncommited changes: 1
Repositories ahead of remote: 1
Repositories behind remote: 1
```
