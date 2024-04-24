Repowatch - a tool to keep an eye on your local git repositories

Commands:
* Add
    Add a new repository to your watchlist.
* Remove
    Remove a repository from your watchlist.
* List
    See all the repositories you're currently watching.
    * Clean
        Remove unavailable repositories.
    * Wipe
        Clear your entire watchlist.
* Status
    See if a repository is being watched and if it's available.
* Find
    Search for git repositories in a directory and select ones to watch.
* Report
    Get a detailed and summarized report on the state of your repositories.
* Resolve
    Resolve all trivial cases.
* Autoreport
    Configure how often repowatch checks your repositories and sends you notifications.

Configuration in the config file:
* WATCHFILE
    The file storing your watched repositories.
* AUTOSCAN_RESOLVE
    Automatically resolve simple update cases.
* NOTIFY_OFFLINE
    Receive notifications even when offline.
* PING_DOMAIN
    Domain used to check internet connection.

Additional Notes:
"Trivial cases" don't require merging or committing.