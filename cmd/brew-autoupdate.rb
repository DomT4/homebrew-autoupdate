#:  * `autoupdate --start` [`--upgrade`] [`--cleanup`]:
#:    Start autoupdating every 24 hours.
#:
#:    If `--upgrade` is specified, also automatically upgrade your packages.
#:
#:    If `--cleanup` is specified, also automatically cleanup old packages after upgrade.
#:
#:  * `autoupdate --stop`:
#:    Stop autoupdating, but retain plist & logs.
#:
#:  * `autoupdate --delete`:
#:    Cancel the autoupdate, delete the plist and logs.
#:
#:  * `autoupdate --version`:
#:    Output this tool's current version.

REPO = File.expand_path("#{File.dirname(__FILE__)}/..")
LIBS = Pathname.new(REPO)/"lib"
$LOAD_PATH.unshift(LIBS) unless $LOAD_PATH.include?(LIBS)

require "autoupdate"

Autoupdate.version if ARGV.include? "--version"
Autoupdate.start if ARGV.include? "--start"
Autoupdate.stop if ARGV.include? "--stop"
Autoupdate.delete if ARGV.include? "--delete"
