# frozen_string_literal: true

module Homebrew
  module_function

  def autoupdate_args
    Homebrew::CLI::Parser.new do
      usage_banner "`autoupdate` (<--start>= [<options>]|<--stop>|<--delete>|<--status>)"
      usage_banner "`autoupdate` <subcomand> [<interval>] [<options>]"
      description <<~EOS
        An easy, convenient way to automatically update Homebrew.

        This script will run `brew update` in the background once every 24 hours (by default) until
        explicitly told to stop, utilising `launchd`.

        `brew upgrade` and `brew cleanup` can also be handled automatically but are optional flags.

        Notifications are enabled by default on macOS Big Sur using a new, codesigned, universal
        AppleScript applet. On older versions of macOS, if you have `terminal-notifier` installed
        you can also request desktop notifications when this command runs.
      EOS
      switch "--start",
             description: "Start autoupdating either once every `interval` hours or once every 24 hours. " \
                          "Please note the interval has to be passed in seconds, so 12 hours would be: " \
                          "`brew autoupdate --start 43200`."
      switch "--upgrade",
             depends_on:  "--start",
             description: "Automatically upgrade your installed formulae. If the Caskroom exists locally " \
                          "Casks will be upgraded as well."
      switch "--cleanup",
             depends_on:  "--start",
             description: "Automatically clean brew's cache and logs."
      switch "--enable-notification",
             depends_on:  "--start",
             description: "Send a notification when the autoupdate process has finished successfully, " \
                          "if `terminal-notifier` is installed & found. Note that currently a new " \
                          "experimental notifier runs automatically on macOS Big Sur, without requiring " \
                          "any external dependencies."
      switch "--stop",
             description: "Stop autoupdating, but retain plist & logs."
      switch "--delete",
             description: "Cancel the autoupdate, delete the plist and logs."
      switch "--status",
             description: "Prints the current status of this tool."
      switch "--version",
             description: "Output this tool's current version."

      %w[--start --stop --delete --status --version].combination(2).each do |conflict|
        conflicts(*conflict)
      end
      named_args :interval, max: 1
    end
  end

  REPO = File.expand_path("#{File.dirname(__FILE__)}/..").freeze
  LIBS = (Pathname.new(REPO)/"lib").freeze

  def autoupdate
    args = autoupdate_args.parse

    if !args.no_named? && !args.start?
      raise UsageError, "This command does not take named arguments without `--start`."
    end
    if args.start? && !args.named.first.match?(/^\d+$/)
      raise UsageError, "This command only accepts integer arguments."
    end

    $LOAD_PATH.unshift(LIBS) unless $LOAD_PATH.include?(LIBS)

    require "autoupdate"

    # Only one option can be specified because of the conflicts defined in autoupdate_args
    Autoupdate.version if args.version?
    Autoupdate.start(args: args) if args.start
    Autoupdate.stop if args.stop?
    Autoupdate.delete if args.delete?
    Autoupdate.status if args.status?
  end
end
