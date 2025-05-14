# frozen_string_literal: true

module Homebrew
  module Cmd
    class Autoupdate < AbstractCommand
      SUBCOMMANDS = %w[start stop delete status version].freeze

      cmd_args do
        usage_banner "`autoupdate` <subcommand> [<interval>] [<options>]"

        description <<~EOS
          An easy, convenient way to automatically update Homebrew.

          This script will run `brew update` in the background once every 24 hours (by default)
          until explicitly told to stop, utilising `launchd`.

          `brew autoupdate start` [<interval>] [<options>]:
          Start autoupdating either once every `interval` hours or once every 24 hours.
          Please note the interval has to be passed in seconds, so 12 hours would be
          `brew autoupdate start 43200`. If you want to start the autoupdate immediately
          and on system boot, pass `--immediate`. Pass `--upgrade` or `--cleanup`
          to automatically run `brew upgrade` and/or `brew cleanup` respectively.

          `brew autoupdate stop`:
          Stop autoupdating, but retain plist and logs.

          `brew autoupdate delete`:
          Cancel the autoupdate, delete the plist and logs.

          `brew autoupdate status`:
          Print the current status of this tool.

          `brew autoupdate version`:
          Output this tool's current version, and a short changelog.
        EOS

        # We want to add the -- versions of subcommands as valid arguments
        # but only when executing the command, not when displaying the help text
        SUBCOMMANDS.each do |subcommand|
          switch "--#{subcommand}", hidden: true
        end

        switch "--upgrade",
               description: "Automatically upgrade your installed formulae. If the Caskroom exists locally " \
                            "then casks will be upgraded as well. Must be passed with `start`."
        switch "--greedy",
               description: "Upgrade casks with `--greedy` (include auto-updating casks). " \
                            "Must be passed with `start`."
        switch "--cleanup",
               description: "Automatically clean Homebrew's cache and logs. Must be passed with `start`."
        switch "--immediate",
               description: "Starts the autoupdate command immediately and on system boot, " \
                            "instead of waiting for one interval (24 hours by default) to pass first. " \
                            "Must be passed with `start`."
        switch "--sudo",
               description: "If a cask requires `sudo`, autoupdate will open a GUI to ask for the password. " \
                            "Requires https://formulae.brew.sh/formula/pinentry-mac to be installed."
        switch "--leaves-only",
               description: "Only upgrade formulae that are not dependencies of another installed formula. " \
                            "This provides a safer upgrade strategy by only updating top-level packages. " \
                            "Must be passed with `--upgrade` and `start`."
        switch "--preserve-dock",
               description: "Restores the Dock to the state it was in before autoupdate ran. " \
                            "Must be passed with `start`."

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
        interval = interval_from_args(args:)

        raise UsageError, "This command requires a subcommand argument." if subcommand.nil?
        if subcommand != :start && interval.present?
          raise UsageError, "This command does not take a named argument without `start`."
        end
        if interval.present? && !interval.match?(/^\d+$/)
          raise UsageError, "This subcommand only accepts integer arguments."
        end

        # Don't require anything until this point to keep help speedy.
        require_relative "../lib/autoupdate"

        case subcommand
        when :start
          ::Autoupdate.start(interval:, args:)
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

      def interval_from_args(args:)
        possibilities = args.named.reject { |arg| SUBCOMMANDS.include? arg }
        raise UsageError, "This subcommand does not take more than 1 named argument." if possibilities.length > 1

        possibilities.first
      end
    end
  end
end
