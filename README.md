# Homebrew-autoupdate

An easy, convenient way to automatically update Homebrew.

This script will run once every 24 hours, doing `brew update`.
`brew upgrade` can also be handled automatically but is an optional flag.

[![](http://imgs.xkcd.com/comics/update.png)](https://xkcd.com/1328/)

## How do I tap this repository?

Just `brew tap domt4/autoupdate`.

## Usage

To run the script, you’d just do `brew autoupdate`. The following options are available:

```
Usage:
--start [seconds] = Start autoupdating every 24 hours or with a specified time interval in seconds.
--stop = Stop autoupdating, but retain plist & logs.
--delete = Cancel the autoupdate, delete the plist and logs.
--upgrade = Also automatically upgrade your packages.
--version = Output this tool's current version.
```

## License
Code is under the [BSD 2 Clause (NetBSD) license](https://github.com/DomT4/homebrew-autoupdate/blob/master/LICENSE).
