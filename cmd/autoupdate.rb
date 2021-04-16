# frozen_string_literal: true

module Homebrew
  module_function

  def autoupdate_args
    Homebrew::CLI::Parser.new do
      usage_banner "`autoupdate` <subcommand> [<interval>] [<options>]"
      description <<~EOS
        An easy, convenient way to automatically update Homebrew.

        This script will run `brew update` in the background once every 24 hours (by default)
        until explicitly told to stop, utilising `launchd`.

        `brew autoupdate start` [<`interval`>] [<`options`>]:
        Start autoupdating either once every `interval` hours or once every 24 hours.
        Please note the interval has to be passed in seconds, so 12 hours would be
        `brew autoupdate start 43200`. Pass `--upgrade` or `--cleanup` to automatically
        run `brew upgrade` and/or `brew cleanup` respectively. Pass `--enable-notification`
        to send a notification when the autoupdate process has finished successfully.

        `brew autoupdate stop`:
        Stop autoupdating, but retain plist & logs.

        `brew autoupdate delete`:
        Cancel the autoupdate, delete the plist and logs.

        `brew autoupdate status`:
        Prints the current status of this tool.

        `brew autoupdate version`:
        Output this tool's current version.
      EOS
      switch "--upgrade",
             description: "Automatically upgrade your installed formulae. If the Caskroom exists locally " \
                          "Casks will be upgraded as well.  Must be passed with `start`."
      switch "--cleanup",
             description: "Automatically clean brew's cache and logs. Must be passed with `start`."
      switch "--enable-notification",
             description: "Send a notification when the autoupdate process has finished successfully, " \
                          "if `terminal-notifier` is installed & found. Note that currently a new " \
                          "experimental notifier runs automatically on macOS Big Sur, without requiring " \
                          "any external dependencies. Must be passed with `start`."

      named_args %w[start stop delete status version], min: 1, max: 2
    end
  end

  REPO = File.expand_path("#{File.dirname(__FILE__)}/..").freeze
  LIBS = (Pathname.new(REPO)/"lib").freeze

  def autoupdate
    args = autoupdate_args.parse

    if args.named.count > 1 && %w[start --start].exclude?(args.named.first)
      raise UsageError, "This command does not take a named argument without `start`."
    end
    if args.named.count > 1 && !args.named.second.match?(/^\d+$/)
      raise UsageError, "This command only accepts integer arguments."
    end

    $LOAD_PATH.unshift(LIBS) unless $LOAD_PATH.include?(LIBS)

    require "autoupdate"

    case args.named.first
    when "start", "--start"
      Autoupdate.start(args: args)
    when "stop", "--stop"
      Autoupdate.stop
    when "delete", "--delete"
      Autoupdate.delete
    when "status", "--status"
      Autoupdate.status
    when "version", "--version"
      Autoupdate.version
    else
      raise UsageError, "Unknown subcommand: #{args.named.first}"
    end
  end
end
