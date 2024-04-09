# repowatch - A tool to manage local git repositories

usage: `repowatch [--help] <command> [<args>]`

### Commands:
- [x] `add <.git directory path>` 
    
    Add a repository to the watchlist
- [x] `rm <.git directory path>`

    Remove a repository from the watchlist
- [x] `list`

    Display all watched repositories
- [x] `status <.git directory path>`

    Show the status of a given repository (watched, available)
- [x] `clean`

    Remove all unavailable repositories (deleted, without permissions, unmounted)
- [x] `wipe`

    Remove all repositories from the list
- [x] `find <directory> [-w]`

    Find all repositories in a given directory. By default it omits already watched repositories. -w flags includes watched repositories.
- [ ] `report [<.git directory path>] [-s]`

    If given a path, report the state of this repository. Otherwise report the state of all watched repositories. `-s` flag tells the program to only report the number of successes/failures without displaying data for each repository.
- [ ] `apply`

    Resolve all trivial cases (only push or only pull)
- [ ] `autoreport <never|hourly|daily|weekly|monthly>`

    Set background checks frequency
- [ ] `gui`

    Launch a zenity based graphical user interface.

### See `config.config` for additional configuration:
* `WATCHFILE`

    A file to store watched repositories
* `AUTOSCAN_PUSH`

    Whether or not the autoscan should push trivial cases 
* `AUTOSCAN_PULL`

    Whether or not the autoscan should pull trivial cases 
* `NOTIFY_OFFLINE`

    Whether or not the autoscan should send you a notification when you're offline