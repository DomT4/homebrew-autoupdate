# Homebrew-autoupdate

An easy, convenient way to automatically update Homebrew.

This script will run once every 24 hours, doing `brew update`.
`brew upgrade` and `brew cleanup` can also be handled automatically but are
optional flags.

[![](https://imgs.xkcd.com/comics/update.png)](https://xkcd.com/1328/)

## How do I install this command?

Just `brew tap domt4/autoupdate`.

## Usage

```
brew autoupdate --start [--upgrade] [--cleanup] [--enable-notification]:
    Start autoupdating every 24 hours.

    If --upgrade is specified, also automatically upgrade your packages.

    If --cleanup is specified, also automatically cleanup old packages after upgrade.

    If --enable-notification is specified, send a notification when the
    autoupdate process has finished successfully, if terminal-notifier
    is installed & found.

brew autoupdate --stop:
    Stop autoupdating, but retain plist & logs.

brew autoupdate --delete:
    Cancel the autoupdate, delete the plist and logs.

brew autoupdate --version:
    Output this tool's current version.
```

It's not required but if you use this update script I'd recommend not permitting
Homebrew to automatically update itself _every time_ `brew install`,
`brew upgrade` or ` brew tap` are executed by adding this to your shell profile:

```
export HOMEBREW_NO_AUTO_UPDATE="1"
```

## License
Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/DomT4/homebrew-autoupdate/blob/master/LICENSE).
