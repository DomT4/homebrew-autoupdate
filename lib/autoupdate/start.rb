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
      auto_args << Autoupdate::Core.command_upgrade.to_s

      if (HOMEBREW_PREFIX/"Caskroom").exist?
        if ENV["SUDO_ASKPASS"].nil? && !args.sudo?
          opoo <<~EOS
            Please note if you use Casks that require `sudo` to upgrade,
            you need to use `--sudo` or define a custom `SUDO_ASKPASS`
            environment variable.

          EOS
        end

        auto_args << Autoupdate::Core.command_cask(args.greedy?).to_s
      end

      auto_args << Autoupdate::Core.command_cleanup.to_s if args.cleanup?
    end

    # Enable the new AppleScript applet by default on Catalina and above.
    # This enables us to do fairly broad testing with essentially
    # no downside for the user. This will also pave the way for removal of
    # terminal-notifier support, which is effectively dead and problematic
    # upstream. Examples:
    # https://github.com/julienXX/terminal-notifier/pull/289
    # https://github.com/julienXX/terminal-notifier/pull/285
    auto_args << " && #{Autoupdate::Notify.new_notify}" if MacOS.version >= :catalina
    # Otherwise on older platforms fallback to the old terminal-notifier style
    # of notification where requested. This will be removed when the AppleScript
    # applet proves itself consistently reliable & can be considered mostly complete.
    if args.enable_notification? && MacOS.version < :yosemite
      odie "terminal-notifier has deprecated support for anything below Yosemite"
    elsif args.enable_notification? && MacOS.version >= :catalina
      opoo <<~EOS
        Notifications are automatically enabled for macOS Catalina
        and newer using a native Applet. Passing --enable-notification
        is no longer required.

      EOS
    elsif args.enable_notification? && Autoupdate::Notify.notifier
      opoo <<~EOS
        Notification support for macOS versions older than
        Catalina (macOS 10.15) will be removed in October 2022
        due to terminal-notifier essentially being Abandonware.

        Newer versions of macOS are supported by a native Applet.
      EOS
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

    if args.sudo?
      unless Formula["pinentry-mac"].any_version_installed?
        odie <<~EOS
          `--sudo` requires https://formulae.brew.sh/formula/pinentry-mac to be installed.
          Please run `brew install pinentry-mac` and try again.
        EOS
      end
      set_env << "\n#{Autoupdate::Core.command_sudo}"
      sudo_gui_script_contents = <<~EOS
        #!/bin/sh
        PATH='#{HOMEBREW_PREFIX}/bin'
        printf "%s\n" "SETOK OK" "SETCANCEL Cancel" "SETDESC homebrew-autoupdate needs your admin password to complete the upgrade" "SETPROMPT Enter Password:" "SETTITLE homebrew-autoupdate Password Request" "GETPIN" | pinentry-mac --no-global-grab --timeout 60 | /usr/bin/awk '/^D / {print substr($0, index($0, $2))}'
      EOS
    elsif env_sudo
      set_env << "\nexport SUDO_ASKPASS=#{env_sudo}"
    end

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

    if args.sudo? && !File.exist?(Autoupdate::Core.location/"brew_autoupdate_sudo_gui")
      File.open(Autoupdate::Core.location/"brew_autoupdate_sudo_gui", "w") { |sc| sc << sudo_gui_script_contents }
      FileUtils.chmod 0555, Autoupdate::Core.location/"brew_autoupdate_sudo_gui"
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
    update_message = "Homebrew will now automatically update every #{interval_to_hours} hours"
    if args.immediate?
      puts "#{update_message}, now, and on system boot."
    else
      puts "#{update_message}."
    end
  end
end
