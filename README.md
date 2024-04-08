# repowatch - A tool to manage local git repositories

usage: `repowatch [--help] <command> [<args>]`

### Commands:
* `add <.git directory>` 
    
    Add a repository to the watchlist
* `rm <.git directory>`

    Remove a repository from the watchlist
* `find <directory>`

    Find all repositories in a given directory
* `scan`

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