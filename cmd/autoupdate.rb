# frozen_string_literal: true

require "cli/parser"

module Homebrew
  module_function

  SUBCOMMANDS = %w[start stop delete status version].freeze

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
        `brew autoupdate start 43200`. If you want to start the autoupdate immediately
        and on system boot, pass `--immediate`. Pass `--upgrade` or `--cleanup`
        to automatically run `brew upgrade` and/or `brew cleanup` respectively.
        Pass `--enable-notification` to send a notification when the autoupdate
        process has finished successfully.

        `brew autoupdate stop`:
        Stop autoupdating, but retain plist and logs.

        `brew autoupdate delete`:
        Cancel the autoupdate, delete the plist and logs.

        `brew autoupdate status`:
        Print the current status of this tool.

        `brew autoupdate version`:
        Output this tool's current version, and a short changelog.
      EOS
      switch "--upgrade",
             description: "Automatically upgrade your installed formulae. If the Caskroom exists locally " \
                          "then casks will be upgraded as well. Must be passed with `start`."
      switch "--greedy",
             description: "Upgrade casks with `--greedy` (include auto-updating casks). " \
                          "Must be passed with `start`."
      switch "--cleanup",
             description: "Automatically clean Homebrew's cache and logs. Must be passed with `start`."
      switch "--enable-notification",
             description: "Send a notification when the autoupdate process has finished successfully, " \
                          "if `terminal-notifier` is installed and found. Must be passed with `start`. " \
                          "Note: notifications are enabled by default on macOS Catalina and newer."
      switch "--immediate",
             description: "Starts the autoupdate command immediately and on system boot, " \
                          "instead of waiting for one interval (24 hours by default) to pass first. " \
                          "Must be passed with `start`."
      switch "--sudo",
             description: "If a cask requires `sudo`, autoupdate will open a GUI to ask for the password. " \
                          "Requires https://formulae.brew.sh/formula/pinentry-mac to be installed."
      switch "--ac-only",
             description: "Only run autoupdate when on AC power. Must be passed with `start`."
      named_args SUBCOMMANDS
    end
  end

  def autoupdate
    # We want to add the -- versions of subcommands as valid arguments
    # but only when executing the command, not when displaying the help text
    parser = autoupdate_args
    SUBCOMMANDS.each do |subcommand|
      parser.switch "--#{subcommand}"
    end
    args = parser.parse

    subcommand = subcommand_from_args(args: args)
    interval = interval_from_args(args: args)

    raise UsageError, "This command requires a subcommand argument." if subcommand.nil?
    if subcommand != :start && interval.present?
      raise UsageError, "This command does not take a named argument without `start`."
    end
    if interval.present? && !interval.match?(/^\d+$/)
      raise UsageError, "This subcommand only accepts integer arguments."
    end

    # This entire tool is essentially a "bells and whistles" wrapper around
    # `launchd` so Linux support is a no-go unless someone wants to put
    # the work in to add/support it in a sustainable manner.
    raise UsageError, "`brew autoupdate` is supported only on macOS!" unless OS.mac?

    # Don't require anything until this point to keep help speedy.
    require_relative "../lib/autoupdate"

    case subcommand
    when :start
      Autoupdate.start(interval: interval, args: args)
    when :stop
      Autoupdate.stop
    when :delete
      Autoupdate.delete
    when :status
      Autoupdate.status
    when :version
      Autoupdate.version
    else
      raise UsageError, "Unknown subcommand: #{args.named.first}"
    end
  end

  def subcommand_from_args(args:)
    choice = nil
    SUBCOMMANDS.each do |subcommand|
      next if args.named.first != subcommand && !args.send(:"#{subcommand}?")
      raise UsageError, "Conflicting subcommands specified." if choice.present?

      choice = subcommand.to_sym
    end
    choice
  end

  def interval_from_args(args:)
    possibilities = args.named.reject { |arg| SUBCOMMANDS.include? arg }
    raise UsageError, "This subcommand does not take more than 1 named argument." if possibilities.length > 1

    possibilities.first
  end
end
