# Homebrew Autoupdate

An easy, convenient way to automatically update Homebrew.

This script will run `brew update` in the background once every 24 hours (by
default) until explicitly told to stop, utilising `launchd`.

`brew upgrade` and `brew cleanup` can also be handled automatically, but
are optional flags.

Notifications are enabled by default using a new, code-signed, universal AppleScript applet.

![A comic highlighting humanity's habit of skipping important updates](https://imgs.xkcd.com/comics/update.png)

## Installing this command

Just `brew tap domt4/autoupdate`.

Now run `brew autoupdate start [schedule/interval] [options]` to enable autoupdate.

## Example

```sh
brew autoupdate start 0-12--- --upgrade --cleanup --immediate --sudo
```

This will upgrade all your casks and formulae would run autoupdate every day at noon (12:00) and on every system boot. <br>
If a sudo password is required for an upgrade, a GUI to enter your password will be displayed. <br>
Also, it will clean up every old version and left-over files.

Casks that have built-in auto-updates enabled by default will not be upgraded.

## Usage

[comment]: # (HELP-COMMAND-OUTPUT:START)

```help
Usage: brew autoupdate subcommand [schedule/interval] [options]

    An easy, convenient way to automatically update Homebrew.

    This script will run brew update in the background every day at noon
(12:00) (by default)
    until explicitly told to stop, utilizing launchd. If the computer is
asleep at the
  scheduled time, it will start as soon the computer is awake.

  brew autoupdate start [schedule/interval] [options]
  Start autoupdate either by defining a schedule or an interval.

   brew autoupdate start --upgrade --cleanup --immediate --sudo
  This will upgrade all your casks and formulae every day at noon (12:00) and on
every system boot.
  If a sudo password is required for an upgrade, a GUI to enter your password
will be displayed.
  Also, it will clean up every old version and left-over files.
  Casks that have built-in auto-updates enabled by default will not be upgraded.

  A schedule is a string of five hyphen-separated digits in a cron like
format.
  Minute(0-59)-Hour(0-23)-Day(1-31)-Weekday(0-7)-Month(1-12)
  Missing values are considered wildcards.
  For example: brew autoupdate start 0-12--- would run autoupdate every day at
noon (12:00).
  For more information on StartCalendarInterval, see man launchd.plist.

  A interval has to be passed in seconds, so 12 hours would be
  brew autoupdate start 43200.
  The exact time of execution depends on the last system boot.
  If the computer is asleep at the scheduled time, the interval will be skipped.
  This could lead to skipped intervals and is therefor not a recommended option.
  Use a schedule instead.

  If you want to start the autoupdate immediately and on system boot,
  pass --immediate. Pass --upgrade or --cleanupto automatically run brew
upgrade
  and/or brew cleanup respectively.

brew autoupdate stop:
    Stop autoupdating, but retain plist and logs.

brew autoupdate delete:
    Cancel the autoupdate, delete the plist and logs.

brew autoupdate status:
    Print the current status of this tool.

    brew autoupdate version:
    Output this tool's current version, and a short changelog.

      --upgrade                    Automatically upgrade your installed
                                   formulae. If the Caskroom exists locally then
                                   casks will be upgraded as well. Must be
                                   passed with start.
      --greedy                     Upgrade casks with --greedy (include
                                   auto-updating casks). Must be passed with
                                   start.
      --cleanup                    Automatically clean Homebrew's cache and
                                   logs. Must be passed with start.
      --enable-notification        Notifications are enabled by default on macOS
                                   Catalina and newer. This flag is no longer
                                   required and can be safely dropped.
      --immediate                  Starts the autoupdate command immediately and
                                   on system boot, instead of waiting for one
                                   interval (24 hours by default) to pass first.
                                   Must be passed with start.
      --sudo                       If a cask requires sudo, autoupdate will
                                   open a GUI to ask for the password. Requires
                                   https://formulae.brew.sh/formula/pinentry-mac
                                   to be installed.
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

[comment]: # (HELP-COMMAND-OUTPUT:END)

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

```sh
export HOMEBREW_AUTO_UPDATE_SECS="86400"
```

or if you wish to disable the built-in autoupdate mechanism entirely:

```sh
export HOMEBREW_NO_AUTO_UPDATE="1"
```

Please note that Homebrew slightly frowns upon people disabling the built-in
autoupdate mechanism.

## TO-DO (PRs Welcome)

## History

This tap was created by [DomT4](https://github.com/DomT4) in April 2015 to
address a personal desire for a background updater, before being moved to
the Homebrew organisation in April 2021 to become an official part of the
project after gaining somewhat widespread usage, something I'm both surprised
by, but also very appreciative of people finding a small tool I wrote so
useful & contributing their own ideas and time towards.

It was in late 2023 moved back to DomT4's ownership to reduce the burden on
the wider Homebrew leadership team in terms of maintenance/support requests.

## License

Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/DomT4/homebrew-autoupdate/blob/master/LICENSE.txt).
