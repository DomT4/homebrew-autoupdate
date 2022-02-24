# frozen_string_literal: false

module Autoupdate
  module_function

  def start(interval:, args:)
    # Method from Homebrew.
    # https://github.com/Homebrew/brew/blob/c9c7f4/Library/Homebrew/utils/popen.rb
    if Utils.popen_read("/bin/launchctl", "list").include?(Autoupdate::Core.name)
      odie <<~EOS
        The command already appears to have been started.
        Please run `brew autoupdate delete` and try again.
      EOS
    end

    auto_args = "update"
    # Spacing at start of lines is deliberate. Don't undo.
    if args.upgrade?
      auto_args << " && #{Autoupdate::Core.brew} upgrade --formula -v"

      if (HOMEBREW_PREFIX/"Caskroom").exist?
        # Support unattended Cask upgrades that require `sudo` where possible.
        # Homebrew themselves permit this same workaround so if they're
        # comfortable enough with it I can tolerate it. Please consider the
        # risks of leaving your admin password laying around the system in
        # plaintext before using this, if you have no other use case for SUDO_ASKPASS.
        if ENV["SUDO_ASKPASS"].nil?
          opoo <<~EOS
            Please note if you use Casks that require `sudo` to upgrade there
            are known issues with that use case and this command unless using
            `SUDO_ASKPASS`.

              https://github.com/Homebrew/homebrew-autoupdate/issues/40

          EOS
        end

        greedy = args.greedy? ? " --greedy" : ""
        auto_args << " && #{Autoupdate::Core.brew} upgrade --cask -v#{greedy}"
      end

      auto_args << " && #{Autoupdate::Core.brew} cleanup" if args.cleanup?
    end

    # Enable the new AppleScript applet by default on Big Sur. This enables us
    # to do fairly broad testing with essentially no downside for the user.
    auto_args << " && #{Autoupdate::Notify.new_notify}" if MacOS.version >= :catalina
    # Otherwise on older platforms fallback to the old terminal-notifier style
    # of notification where requested. This will be removed when the AppleScript
    # applet proves itself consistently reliable & can be considered mostly complete.
    if args.enable_notification? && MacOS.version < :yosemite
      odie "terminal-notifier has deprecated support for anything below Yosemite"
    elsif args.enable_notification? && Autoupdate::Notify.notifier
      auto_args << " && #{Autoupdate::Notify.notify}"
    end

    # Try to respect user choice as much as possible.
    env_cache = ENV.fetch("HOMEBREW_CACHE") if ENV["HOMEBREW_CACHE"]
    env_logs = ENV.fetch("HOMEBREW_LOGS") if ENV["HOMEBREW_LOGS"]
    env_dev = ENV.fetch("HOMEBREW_DEVELOPER") if ENV["HOMEBREW_DEVELOPER"]
    env_stats = ENV.fetch("HOMEBREW_NO_ANALYTICS") if ENV["HOMEBREW_NO_ANALYTICS"]
    env_cask = ENV.fetch("HOMEBREW_CASK_OPTS") if ENV["HOMEBREW_CASK_OPTS"]
    env_sudo = ENV.fetch("SUDO_ASKPASS") if ENV["SUDO_ASKPASS"]
    env_path = ENV.fetch("PATH")

    # We don't want a background task ramping up the user's CPU to build things
    # from source, especially since it'll be non-obvious why the CPU is
    # suddenly being worked hard.
    set_env = "export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1"

    set_env << "\nexport PATH='#{env_path}'"
    set_env << "\nexport HOMEBREW_CACHE='#{env_cache}'" if env_cache
    set_env << "\nexport HOMEBREW_LOGS='#{env_logs}'" if env_logs
    set_env << "\nexport HOMEBREW_DEVELOPER=#{env_dev}" if env_dev
    set_env << "\nexport HOMEBREW_NO_ANALYTICS=#{env_stats}" if env_stats
    set_env << "\nexport HOMEBREW_CASK_OPTS=#{env_cask}" if env_cask
    set_env << "\nexport SUDO_ASKPASS=#{env_sudo}" if env_sudo

    script_contents = <<~EOS
      #!/bin/sh
      #{set_env}
      /bin/date && #{Autoupdate::Core.brew} #{auto_args}
    EOS
    FileUtils.mkpath(Autoupdate::Core.logs)
    FileUtils.mkpath(Autoupdate::Core.location)

    # It's not something I particularly support but if someone manually loads
    # the plist with launchctl themselves we can end up with a log directory
    # we can't write to later, so need to ensure a future `start` command
    # doesn't silently fail.
    if File.writable?(Autoupdate::Core.logs)
      log_out = "#{Autoupdate::Core.logs}/#{Autoupdate::Core.name}.out"
    elsif File.writable?(Autoupdate::Core.fallback_logs)
      log_out = "#{Autoupdate::Core.fallback_logs}/#{Autoupdate::Core.name}.out"
    else
      puts <<~EOS
        #{Autoupdate::Core.logs} does not seem to be writable.
        You may wish to `chown` it back to your user.
      EOS
    end

    # Security tools like "Little Snitch" only display the executable name by
    # default, which makes this generic name a little worrying without context.
    # Rename the old script to the new script name, which should provide more
    # clarity to users who run systems with tools like LS installed.
    if File.exist?(Autoupdate::Core.location/"updater")
      FileUtils.cp Autoupdate::Core.location/"updater", Autoupdate::Core.location/"brew_autoupdate"
    end

    # If someone has previously stopped the command assume when they start
    # it again they'd want to keep the same options & don't replace the script.
    # If you want to tweak prior-provided options the expected way is with the
    # delete command followed by the start command with new args.
    unless File.exist?(Autoupdate::Core.location/"brew_autoupdate")
      File.open(Autoupdate::Core.location/"brew_autoupdate", "w") { |sc| sc << script_contents }
      FileUtils.chmod 0555, Autoupdate::Core.location/"brew_autoupdate"
    end

    interval ||= "86400"

    # This restores the "Run At Load" key removed in a7de771abcf6 when requested.
    launch_immediately = if args.immediate?
      <<~EOS
        <key>RunAtLoad</key>
          <true/>
      EOS
    else
      ""
    end

    file = <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{Autoupdate::Core.name}</string>
        <key>Program</key>
        <string>#{Autoupdate::Core.location}/brew_autoupdate</string>
        <key>ProgramArguments</key>
        <array>
            <string>#{Autoupdate::Core.location}/brew_autoupdate</string>
        </array>
        #{launch_immediately.chomp}
        <key>StandardErrorPath</key>
        <string>#{log_out}</string>
        <key>StandardOutPath</key>
        <string>#{log_out}</string>
        <key>StartInterval</key>
        <integer>#{interval}</integer>
        <key>LowPriorityBackgroundIO</key>
        <true/>
        <key>LowPriorityIO</key>
        <true/>
        <key>ProcessType</key>
        <string>Background</string>
      </dict>
      </plist>
    EOS

    # https://github.com/Homebrew/homebrew-autoupdate/issues/10
    user_la = Pathname.new(Autoupdate::Core.plist).dirname
    unless user_la.exist?
      odie <<~EOS
        #{user_la} does not exist. Please create it first:
          mkdir -p #{user_la}
        You may need to use `sudo`.
      EOS
    end

    File.open(Autoupdate::Core.plist, "w") { |f| f << file }
    quiet_system "/bin/launchctl", "load", Autoupdate::Core.plist

    # This should round to a whole number consistently.
    # It'll behave strangely if someone wants autoupdate
    # to run more than once an hour, but... surely not?
    interval_to_hours = interval.to_i / 60 / 60
    puts "Homebrew will now automatically update every #{interval_to_hours} hours, or on system boot."
  end
end
