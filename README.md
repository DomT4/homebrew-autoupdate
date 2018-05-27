# Homebrew-autoupdate

An easy, convenient way to automatically update Homebrew.

This script will run once every 24 hours, running `brew update`.

`brew upgrade` and `brew cleanup` can also be handled automatically but
are optional flags. If you have `terminal-notifier` installed you can
also request desktop notifications when this command runs.

[![](https://imgs.xkcd.com/comics/update.png)](https://xkcd.com/1328/)

## Installing this command

Just `brew tap domt4/autoupdate`.

## Usage

```
brew autoupdate --start [--upgrade] [--cleanup] [--enable-notification]:
    Start autoupdating every 24 hours.

    If --upgrade is specified, autoupdate will also upgrade your installed
    formulae. If the Caskroom exists locally Casks will be upgraded as well.

    If --cleanup is specified, autoupdate will also automatically clean
    brew's cache and logs.

    If --enable-notification is specified, autoupdate will send a notification
    when the autoupdate process has finished successfully, if terminal-notifier
    is installed & found.

brew autoupdate --stop:
    Stop autoupdating, but retain plist & logs.

brew autoupdate --delete:
    Cancel the autoupdate, delete the plist and logs.

brew autoupdate --version:
    Output this tool's current version.
```

## This Vs brew's built-in autoupdate mechanism

This command mostly exists to ensure Homebrew is updated regardless of whether
you invoke `brew` or not, which is the primary difference from the autoupdate
mechanism built into `brew`, the latter requiring a user to explicitly run
any of `brew install`, `brew tap` or `brew upgrade`.

If you run `brew` commands regularly yourself, you may wish to consider using
the built-in autoupdate mechanism, which can be instructed to autoupdate less
often or disabled entirely. If you wish to update every 24 hours using the
built-in autoupdate mechanism set this in your environment:

```bash
export HOMEBREW_AUTO_UPDATE_SECS="86400"
```

or if you wish to disable the built-in autoupdate mechanism entirely:

```bash
export HOMEBREW_NO_AUTO_UPDATE="1"
```

Please note that Homebrew themselves slightly frown upon people disabling
the built-in autoupdate mechanism.

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/DomT4/homebrew-autoupdate/blob/master/LICENSE).
