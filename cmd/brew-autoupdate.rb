REPO = File.expand_path("#{File.dirname(__FILE__)}/..")
LIBS = Pathname.new(REPO)/"lib"
$LOAD_PATH.unshift(LIBS) unless $LOAD_PATH.include?(LIBS)

require "autoupdate"

puts Autoupdate.usage if ARGV.empty? || ARGV.include?("--help") || ARGV.include?("-h")
Autoupdate.version if ARGV.include? "--version"
Autoupdate.start if ARGV.include? "--start"
Autoupdate.stop if ARGV.include? "--stop"
Autoupdate.delete if ARGV.include? "--delete"
