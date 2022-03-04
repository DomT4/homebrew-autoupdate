# Homebrew Autoupdate

An easy, convenient way to automatically update Homebrew.

This script will run `brew update` in the background once every 24 hours (by
default) until explicitly told to stop, utilising `launchd`.

`brew upgrade` and `brew cleanup` can also be handled automatically but
are optional flags.

Notifications are enabled by default on macOS Big Sur using a new,
codesigned, universal AppleScript applet. On older versions of macOS, if you
have `terminal-notifier` installed you can also request desktop notifications
when this command runs.

![A comic highlighting humanity's habit of skipping important updates](https://imgs.xkcd.com/comics/update.png)

## Installing this command

Just `brew tap homebrew/autoupdate`.

## Usage

```
Usage: brew autoupdate subcommand [interval] [options]

An easy, convenient way to automatically update Homebrew.

This script will run brew update in the background once every 24 hours (by
default) until explicitly told to stop, utilising launchd.

brew autoupdate start [interval] [options]:
    Start autoupdating either once every interval hours or once every 24
hours. Please note the interval has to be passed in seconds, so 12 hours would
be brew autoupdate start 43200. Pass --upgrade or --cleanup to
automatically run brew upgrade and/or brew cleanup respectively. Pass
--enable-notification to send a notification when the autoupdate process has
finished successfully.

brew autoupdate stop:
    Stop autoupdating, but retain plist & logs.

brew autoupdate delete:
    Cancel the autoupdate, delete the plist and logs.

brew autoupdate status:
    Prints the current status of this tool.

brew autoupdate version:
    Output this tool's current version, and a short changelog.

      --upgrade                    Automatically upgrade your installed
                                   formulae. If the Caskroom exists locally
                                   Casks will be upgraded as well. Must be
                                   passed with start.
      --greedy                     Upgrade casks with --greedy. See brew(1).
                                   Must be passed with start.
      --cleanup                    Automatically clean brew's cache and logs.
                                   Must be passed with start.
      --enable-notification        Send a notification when the autoupdate
                                   process has finished successfully, if
                                   terminal-notifier is installed & found.
                                   Must be passed with start.
                                   NOTE: Notifications are enabled by default
                                   on macOS Catalina and newer.
      --immediate                  Starts the autoupdate command immediately,
                                   instead of waiting for one interval (24
                                   hours by default) to pass first. Must be
                                   passed with start.
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

**Logs of the performed operations can be found at:** `~/Library/Logs/com.github.domt4.homebrew-autoupdate`

## This vs `brew`'s built-in autoupdate mechanism

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

Please note that Homebrew slightly frowns upon people disabling the built-in
autoupdate mechanism.

## TO-DO (PRs Welcome)

* Complete broader testing and roll-out of new, experimental notification
support added in [6365cc020](https://github.com/Homebrew/homebrew-autoupdate/commit/6365cc020)
that doesn't require or use any external dependencies, using only an Applescript
applet.
[Related Issue](https://github.com/Homebrew/homebrew-autoupdate/issues/25)

* Decide what to do about Cask upgrades which require `sudo` to succeed
and currently just hang when that situation is encountered,
unless using `SUDO_ASKPASS`.
[Related Issue](https://github.com/Homebrew/homebrew-autoupdate/issues/40)

## History

This tap was created by [DomT4](https://github.com/DomT4) in April 2015 to
address a personal desire for a background updater, before being moved to
the Homebrew organisation in April 2021 to become an official part of the
project after gaining somewhat widespread usage, something I'm both surprised
by but also very appreciative of people finding a small tool I wrote so
useful & contributing their own ideas and time towards.

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/DomT4/homebrew-autoupdate/blob/master/LICENSE.txt).
