usage: repowatch [--help] <command> [<args>]

A tool to manage local git repositories

The <.git directory path> is a path to the .git directory inside 
your repository, for example `/home/usr/repo/.git`. 

Commands:
    add <.git directory path>     add a repository to the watchlist
    rm <.git directory path>      remove a repository from the watchlist
    list                          display all watched repositories
    status <.git directory path>  show the status of a given repository 
                                    (watched, available)
    clean                         Remove all unavailable repositories
                                    (deleted, without permissions, unmounted)
    wipe                          Remove all repositories from the list
    find <directory> [-w]         Find all repositories in a given directory. 
                                    By default, it omits already watched repositories. 
                                    The `-w` flag includes watched repositories.
    report [<.git directory path>] [-s]    
                                  If given a path, it reports the state of this 
                                    repository. Otherwise, it reports the state of 
                                    all watched repositories. The -s flag tells the 
                                    program to summarize the report without details.
    apply [-s]                    Resolve all trivial cases (only push or only pull). 
                                    The -s flag tells the program to summarize the 
                                    report without details.
    autoreport <never|hourly|daily|weekly|monthly>    
                                  Set the frequency of background checks. Each check 
                                    will send a desktop notification if any repository 
                                    requires attention.
    notify                        Report watched repositories as a notification. 
                                    This is what autoreport looks like.
    gui                           Launch a Zenity-based graphical user interface.

See `config.config` for additional configuration:
    WATCHFILE        A file to store watched repositories.
    AUTOSCAN_PUSH    Whether or not the autoscan should push trivial cases. 
    AUTOSCAN_PULL    Whether or not the autoscan should pull trivial cases.
    NOTIFY_OFFLINE   Whether or not the autoscan should send a notification 
                        when you're offline.
    PING_DOMAIN      A domain the program will ping to check if you're online.


