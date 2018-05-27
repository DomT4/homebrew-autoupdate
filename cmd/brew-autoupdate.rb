#:  * `autoupdate --start` [`--upgrade`] [`--cleanup`] [`--enable-notification`]:
#:    Start autoupdating every 24 hours.
#:
#:    If `--upgrade` is specified, autoupdate will also upgrade your installed
#:    formulae. If the Caskroom exists locally Casks will be upgraded as well.
#:
#:    If `--cleanup` is specified, autoupdate will also automatically clean
#:    brew's cache and logs.
#:
#:    If `--enable-notification` is specified, autoupdate will send a notification
#:    when the autoupdate process has finished successfully, if `terminal-notifier`
#:    is installed & found.
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
