usage: repowatch [--help|--version] <command> [<args>]

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
    find <directory> [-w]         Find all repositories in a given directory. By 
                                    default, it omits already watched repositories. 
                                    The `-w` flag includes watched repositories.
    report [<.git directory path>] [-s]    
                                  If given a path, it reports the state of this 
                                    repository. Otherwise, it reports the state of 
                                    all watched repositories. The -s flag tells the 
                                    program to summarize the report without details.
    resolve [-s]                  Resolve all trivial cases (only push or only pull). 
                                    The -s flag tells the program to summarize the 
                                    report without details.
    autoreport [-l] [-d] [-s <frequency> <delay>] 
                                  Manage the frequency of background checks. 
                                    `-l` flag outputs the current configuration. 
                                    `-d` flag disables autoreport. `-s` flag sets 
                                    a new configuration.
    notify                        Report watched repositories as a notification. 
                                    This is what autoreport looks like.
    gui                           Launch a Zenity-based graphical user interface.

See `config.config` for additional configuration:
    WATCHFILE         A file to store watched repositories.
    AUTOSCAN_RESOLVE  Whether or not the autoscan should resolve trivial cases.
    NOTIFY_OFFLINE    Whether or not the autoscan should send a notification 
                         when you're offline.
    PING_DOMAIN       A domain the program will ping to check if you're online.


