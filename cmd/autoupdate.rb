# typed: strict
# frozen_string_literal: true

module Homebrew
  module Cmd
    class Autoupdate < AbstractCommand
      SUBCOMMANDS = %w[start stop delete status version logs].freeze

      cmd_args do
        usage_banner "`autoupdate` <subcommand> [<options>]"

        description <<~EOS
          An easy, convenient way to automatically update Homebrew.

          This script will run `brew update` in the background once every 24 hours (by default)
          until explicitly told to stop, utilising `launchd`.

          Start autoupdating with:
            `brew autoupdate start [<interval>] [<options>]`

          The interval defaults to 24 hours. It can be provided as seconds or as a duration
          such as `30m`, `12h`, `1d`, or `1w`.

          Common start options:
            `--upgrade` upgrades installed formulae and casks.
            `--cleanup` cleans Homebrew's cache and logs after a successful run.
            `--immediate` runs immediately and whenever the launch agent is loaded.
            `--only=wget,node,firefox` upgrades only the listed packages.
            `--leaves-only` upgrades only top-level formulae.
            `--greedy` includes auto-updating casks.
            `--sudo` enables a GUI password prompt for cask upgrades.
            `--ac-only` skips runs while the Mac is on battery power.
            `--notify-on-error` shows notifications only for failed runs.
            `--no-notify` disables notifications.

          Examples:
            `brew autoupdate start`
            `brew autoupdate start 12h --upgrade --cleanup --immediate`
            `brew autoupdate start 1d --upgrade --only=wget,node,firefox`
            `brew autoupdate logs --lines=50`
            `brew autoupdate logs --follow`

          Run `brew autoupdate start --help` or `brew autoupdate logs --help` for
          complete options for those subcommands.
        EOS

        # Preserve the original, undocumented `--start`-style invocations.
        SUBCOMMANDS.each do |subcommand|
          switch "--#{subcommand}", hidden: true
        end

        subcommand "start" do
          usage_banner <<~EOS
            `autoupdate start` [<interval>] [<options>]:
            Start autoupdating in the background.
            The interval defaults to 24 hours and accepts seconds or a suffix such as
            `30m`, `12h`, or `1d`.
          EOS

          switch "--upgrade",
                 description: "Automatically upgrade installed formulae and casks."
          switch "--greedy",
                 depends_on:  "--upgrade",
                 description: "Include auto-updating casks when upgrading."
          switch "--cleanup",
                 description: "Automatically clean Homebrew's cache and logs."
          switch "--immediate",
                 description: "Run immediately and on login instead of waiting for the first interval."
          switch "--sudo",
                 depends_on:  "--upgrade",
                 description: "Open a GUI password prompt when a cask upgrade requires `sudo`. " \
                              "Requires `pinentry-mac` to be installed."
          switch "--leaves-only",
                 depends_on:  "--upgrade",
                 description: "Upgrade only top-level formulae that are not dependencies."
          comma_array "--only=",
                      description: "Upgrade only these formulae and/or casks (comma-separated). " \
                                   "Requires `--upgrade`."
          switch "--ac-only",
                 description: "Run only while the Mac is connected to AC power."
          switch "--notify-on-error",
                 description: "Notify only when an autoupdate run fails."
          switch "--no-notify",
                 description: "Disable autoupdate notifications."

          conflicts "--only", "--leaves-only"
          conflicts "--notify-on-error", "--no-notify"
          named_args max: 1
        end

        subcommand "stop" do
          usage_banner <<~EOS
            `autoupdate stop`:
            Stop autoupdating while retaining the launch agent, configuration, and logs.
          EOS
          named_args :none
        end

        subcommand "delete" do
          usage_banner <<~EOS
            `autoupdate delete`:
            Stop autoupdating and delete its launch agent, configuration, and logs.
          EOS
          named_args :none
        end

        subcommand "status" do
          usage_banner <<~EOS
            `autoupdate status`:
            Show whether autoupdate is running and describe its installed configuration.
          EOS
          named_args :none
        end

        subcommand "version" do
          usage_banner <<~EOS
            `autoupdate version`:
            Show this tool's current version and a short changelog.
          EOS
          named_args :none
        end

        subcommand "logs" do
          usage_banner <<~EOS
            `autoupdate logs` [<options>]:
            Show output from autoupdate runs.
          EOS

          switch "-f", "--follow",
                 description: "Follow the log as new output is written."
          flag "-n=", "--lines=",
               description: "Show this many lines from the end of the log. Defaults to 10."
          named_args :none
        end
      end

      def run
        # This entire tool is essentially a "bells and whistles" wrapper around
        # `launchd` so Linux support is a no-go unless someone wants to put
        # the work in to add/support it in a sustainable manner.
        raise UsageError, "`brew autoupdate` is supported only on macOS!" unless OS.mac?

        subcommand = subcommand_from_args(args:)

        raise UsageError, "This command requires a subcommand argument." if subcommand.nil?

        # Don't require anything until this point to keep help speedy.
        require_relative "../lib/autoupdate"

        case subcommand
        when :start
          raise UsageError, "`--only` cannot be passed without `--upgrade`." if args.only && !args.upgrade?

          interval = begin
            ::Autoupdate::Interval.parse(args.named.first)
          rescue ::Autoupdate::Interval::InvalidIntervalError => e
            raise UsageError, e.message
          end
          ::Autoupdate.start(interval:, args:)
        when :stop
          ::Autoupdate.stop
        when :delete
          ::Autoupdate.delete
        when :status
          ::Autoupdate.status
        when :version
          ::Autoupdate.version
        when :logs
          lines = lines_from_args(args:)
          ::Autoupdate.logs(follow: args.follow?, lines: lines)
        else
          raise UsageError, "Unknown subcommand: #{args.named.first}"
        end
      end

      def subcommand_from_args(args:)
        choices = [args.subcommand]
        SUBCOMMANDS.each do |subcommand|
          choices << subcommand if args.send(:"#{subcommand}?")
        end

        choices.compact!
        raise UsageError, "Conflicting subcommands specified." if choices.uniq.length > 1

        choices.first&.to_sym
      end

      def lines_from_args(args:)
        return 10 if args.lines.blank?

        lines = Integer(args.lines, exception: false)
        raise UsageError, "`--lines` must be a positive integer." unless lines&.positive?

        lines
      end
    end
  end
end
