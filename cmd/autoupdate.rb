# frozen_string_literal: true

module Homebrew
  module Cmd
    class Autoupdate < AbstractCommand
      SUBCOMMANDS = %w[start stop delete status version].freeze

      cmd_args do
        usage_banner "`autoupdate` <subcommand> [<schedule>/<interval>] [<options>]"

        description <<~EOS
          An easy, convenient way to automatically update Homebrew.

          This script will run `brew update` in the background every day at noon (12:00) (by default)
          until explicitly told to stop, utilizing `launchd`. If the computer is asleep at the
        scheduled time, it will start as soon the computer is awake.

        `brew autoupdate start` [<`schedule`>/<`interval`>] [<`options`>]
        Start autoupdate either by defining a `schedule` or an `interval`.

         `brew autoupdate start --upgrade --cleanup --immediate --sudo`
        This will upgrade all your casks and formulae every day at noon (12:00) and on every system boot.
        If a sudo password is required for an upgrade, a GUI to enter your password will be displayed.
        Also, it will clean up every old version and left-over files.
        Casks that have built-in auto-updates enabled by default will not be upgraded.

        A `schedule` is a string of five hyphen-separated digits in a `cron` like format.
        `Minute(0-59)-Hour(0-23)-Day(1-31)-Weekday(0-7)-Month(1-12)`
        Missing values are considered wildcards.
        For example: `brew autoupdate start 0-12---` would run autoupdate every day at noon (12:00).
        For more information on `StartCalendarInterval`, see `man launchd.plist`.

        A `interval` has to be passed in seconds, so 12 hours would be
        `brew autoupdate start 43200`.
        The exact time of execution depends on the last system boot.
        If the computer is asleep at the scheduled time, the interval will be skipped.
        This could lead to skipped intervals and is therefor not a recommended option.
        Use a `schedule` instead.

        If you want to start the autoupdate immediately and on system boot,
        pass `--immediate`. Pass `--upgrade` or `--cleanup`to automatically run `brew upgrade`
        and/or `brew cleanup` respectively.

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
              description: "Notifications are enabled by default on macOS Catalina and newer. This flag " \
                            "is no longer required and can be safely dropped."
        switch "--immediate",
              description: "Starts the autoupdate command immediately and on system boot, " \
                            "instead of waiting for one interval (24 hours by default) to pass first. " \
                            "Must be passed with `start`."
        switch "--sudo",
              description: "If a cask requires `sudo`, autoupdate will open a GUI to ask for the password. " \
                            "Requires https://formulae.brew.sh/formula/pinentry-mac to be installed."

        # Needs to be two as otherwise it breaks the passing of an interval
        # such as: start --immediate 3600. `Error: Invalid usage:`
        named_args SUBCOMMANDS, max: 2
      end

      def run
        # This entire tool is essentially a "bells and whistles" wrapper around
        # `launchd` so Linux support is a no-go unless someone wants to put
        # the work in to add/support it in a sustainable manner.
        raise UsageError, "`brew autoupdate` is supported only on macOS!" unless OS.mac?

        subcommand = subcommand_from_args(args:)
        schedule_or_interval = schedule_or_interval_from_args(args:)

        raise UsageError, "This command requires a subcommand argument." if subcommand.nil?
        if subcommand != :start && schedule_or_interval.present?
          raise UsageError, "This command does not take a named argument without `start`."
        end

        if schedule_or_interval.present? && !(schedule_or_interval.match?(/^\d+$/) \
      || schedule_or_interval.match?(/^.*-.*-.*-.*-.*$/))
          raise UsageError, "This subcommand only accepts a schedule pattern or interval integer as argument."
        end

        # Don't require anything until this point to keep help speedy.
        require_relative "../lib/autoupdate"

        case subcommand
        when :start
          ::Autoupdate.start(schedule_or_interval:, args:)
        when :stop
          ::Autoupdate.stop
        when :delete
          ::Autoupdate.delete
        when :status
          ::Autoupdate.status
        when :version
          ::Autoupdate.version
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

      def schedule_or_interval_from_args(args:)
        possibilities = args.named.reject { |arg| SUBCOMMANDS.include? arg }
        raise UsageError, "This subcommand does not take more than 1 named argument." if possibilities.length > 1

        possibilities.first
      end
    end
  end
end
