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

Now run `brew autoupdate start [interval] [options]` to enable autoupdate.
The interval defaults to 24 hours and accepts seconds or a short duration such
as `30m`, `12h`, or `1d`.

_Note:_
_To ensure that auto-updated cask-based apps are updated in place (so they stay on your Dock), add `~/Library/Application Support/com.github.domt4.homebrew-autoupdate/brew_autoupdate` to System Settings / Privacy and Security / App Management. (Also allow ruby and Terminal.app)_

## Example

```sh
brew autoupdate start 12h --upgrade --cleanup --immediate --sudo
```

This will upgrade all your casks and formulae every 12 hours and on every system boot.
If a sudo password is required for an upgrade, a GUI to enter your password will be displayed.
Also, it will clean up every old version and left-over files.

Casks that have built-in auto-updates enabled by default will not be upgraded.

### Upgrade Only Specific Packages

```sh
brew autoupdate start 12h --upgrade --only=wget,node,firefox
```

This will only auto-upgrade `wget`, `node`, and `firefox` every 12 hours,
leaving all other installed packages untouched. Both formulae and casks are
supported, including tap-qualified names (`homebrew/cask/firefox`) and
versioned formulae (`node@20`).

Cannot be combined with `--leaves-only`. To change which packages are
auto-upgraded, run `brew autoupdate delete` then start again with the new list.

## Usage

<!-- HELP-COMMAND-OUTPUT:START -->

```help
From tap: domt4/autoupdate
Usage: brew autoupdate subcommand [options]

An easy, convenient way to automatically update Homebrew.

This script will run brew update in the background once every 24 hours (by
default) until explicitly told to stop, utilising launchd.

Subcommands:
  start:
    Start autoupdating in the background.
  stop:
    Stop autoupdating while retaining the launch agent, configuration, and logs.
  delete:
    Stop autoupdating and delete its launch agent, configuration, and logs.
  status:
    Show whether autoupdate is running and describe its installed configuration.
  version:
    Show this tool's current version and a short changelog.
  logs:
    Show output from autoupdate runs.

  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.

From tap: domt4/autoupdate
Usage: brew autoupdate start [interval] [options]:
    Start autoupdating in the background. The interval defaults to 24 hours and
accepts seconds or a suffix such as 30m, 12h, or 1d.

  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
      --upgrade                    Automatically upgrade installed formulae and
                                   casks.
      --greedy                     Include auto-updating casks when upgrading.
      --cleanup                    Automatically clean Homebrew's cache and
                                   logs.
      --immediate                  Run immediately and on login instead of
                                   waiting for the first interval.
      --sudo                       Open a GUI password prompt when a cask
                                   upgrade requires sudo. Requires
                                   pinentry-mac to be installed.
      --leaves-only                Upgrade only top-level formulae that are not
                                   dependencies.
      --only                       Upgrade only these formulae and/or casks
                                   (comma-separated). Requires --upgrade.
      --ac-only                    Run only while the Mac is connected to AC
                                   power.

From tap: domt4/autoupdate
Usage: brew autoupdate logs [options]:
    Show output from autoupdate runs.

  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
  -f, --follow                     Follow the log as new output is written.
  -n, --lines                      Show this many lines from the end of the log.
                                   Defaults to 10.
```

<!-- HELP-COMMAND-OUTPUT:END -->

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
