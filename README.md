# Homebrew Autoupdate

An easy, convenient way to automatically update Homebrew.

This script will run `brew update` in the background once every 24 hours (by
default) until explicitly told to stop, utilising `launchd`.

`brew upgrade` and `brew cleanup` can also be handled automatically, but
are optional flags.

Notifications are enabled by default on macOS Big Sur using a new,
code-signed, universal AppleScript applet. On older versions of macOS, if you
have `terminal-notifier` installed, you can also request desktop notifications
when this command runs.

![A comic highlighting humanity's habit of skipping important updates](https://imgs.xkcd.com/comics/update.png)

## Installing this command

Just `brew tap homebrew/autoupdate`.

Now run `brew autoupdate start [schedule/interval] [options]` to enable autoupdate.

## Example

`brew  autoupdate start 0-12--- --upgrade --cleanup --immediate --sudo`

This will upgrade all your casks and formulae would run autoupdate every day at noon (12:00) and on every system boot. <br>
If a sudo password is required for an upgrade, a GUI to enter your password will be displayed. <br>
Also, it will clean up every old version and left-over files.

Casks that have built-in auto-updates enabled by default will not be upgraded.

## Usage

Refer to the link below to find an in-depth description of the commands.

**[Homebrew Documentation autoupdate subcommand](https://docs.brew.sh/Manpage#autoupdate-subcommand-interval-options)**

**Logs of the performed operations can be found at:** `~/Library/Logs/com.github.domt4.homebrew-autoupdate`

## This vs `brew`'s built-in autoupdate mechanism

This command mostly exists to ensure Homebrew is updated regardless of whether
you invoke `brew` or not, which is the primary difference from the autoupdate
mechanism built into `brew`, the latter requiring a user to explicitly run
any of `brew install`, `brew tap` or `brew upgrade`.

If you run `brew` commands regularly yourself, you may wish to consider using
the built-in autoupdate mechanism, which can be instructed to autoupdate less
often, or disabled entirely. If you wish to update every 24 hours using the
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
Support was added in [6365cc020](https://github.com/Homebrew/homebrew-autoupdate/commit/6365cc020)
that doesn't require or use any external dependencies, using only an Applescript
applet.
[Related Issue](https://github.com/Homebrew/homebrew-autoupdate/issues/25)

## History

This tap was created by [DomT4](https://github.com/DomT4) in April 2015 to
address a personal desire for a background updater, before being moved to
the Homebrew organisation in April 2021 to become an official part of the
project after gaining somewhat widespread usage, something I'm both surprised
by, but also very appreciative of people finding a small tool I wrote so
useful & contributing their own ideas and time towards.

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/DomT4/homebrew-autoupdate/blob/master/LICENSE.txt).
