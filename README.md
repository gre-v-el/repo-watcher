# repowatch - A tool to manage local git repositories

usage: `repowatch [--help] <command> [<args>]`

### Commands:
* `add <.git directory path>` 
    
    Add a repository to the watchlist
* `rm <.git directory path>`

    Remove a repository from the watchlist
* `clean`

    Remove all inaccessible repositories (deleted or without permissions)
* `find <directory>`

    Find all repositories in a given directory
* `report`

    Report the state of all watched repositories
* `apply`

    Resolve all trivial cases (only push or only pull)
* `autoscan <never|hourly|daily|weekly|monthly>`

    Set background checks frequency


### See `config.config` for additional configuration:
* `WATCHFILE`

    A file to star watched repositories
* `AUTOSCAN_PUSH`

    Whether or not the autoscan should push trivial cases 
* `AUTOSCAN_PULL`

    Whether or not the autoscan should pull trivial cases 
* `NOTIFY_OFFLINE`

    Whether or not the autoscan should send you a notification when you're offline