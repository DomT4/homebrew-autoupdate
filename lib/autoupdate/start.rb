module Autoupdate
  module_function

  def start
    # Method from Homebrew.
    # https://github.com/Homebrew/brew/blob/c9c7f4/Library/Homebrew/utils/popen.rb
    if Utils.popen_read("/bin/launchctl list").include?(Autoupdate::Core.name)
      puts <<~EOS
        The command already appears to have been started.
        Please run `brew autoupdate --delete` and try again.
      EOS
      exit 1
    end

    auto_args = "update"
    # Spacing at start of lines is deliberate. Don't undo.
    if ARGV.include? "--upgrade"
      auto_args << " && #{Autoupdate::Core.brew} upgrade -v"
      auto_args << " && #{Autoupdate::Core.brew} cask upgrade -v" if (HOMEBREW_PREFIX/"Caskroom").exist?
      auto_args << " && #{Autoupdate::Core.brew} cleanup" if ARGV.include? "--cleanup"
    end
    if ARGV.include?("--enable-notification") && MacOS.version < :yosemite
      puts "terminal-notifier has deprecated support for anything below Yosemite"
      exit 1
    elsif ARGV.include?("--enable-notification") && Autoupdate::Notify.notifier
      auto_args << " && #{Autoupdate::Notify.notify}"
    end

    script_contents = <<~EOS
      #!/bin/sh
      /bin/date && #{Autoupdate::Core.brew} #{auto_args}
    EOS
    FileUtils.mkpath(Autoupdate::Core.logs)
    FileUtils.mkpath(Autoupdate::Core.location)

    # It's not something I particularly support but if someone manually loads
    # the plist with launchctl themselves we can end up with a log directory
    # we can't write to later, so need to ensure a future `start` command
    # doesn't silently fail.
    if File.writable?(Autoupdate::Core.logs)
      log_err = "#{Autoupdate::Core.logs}/#{Autoupdate::Core.name}.err"
      log_std = "#{Autoupdate::Core.logs}/#{Autoupdate::Core.name}.out"
    elsif File.writable?(Autoupdate::Core.fallback_logs)
      log_err = "#{Autoupdate::Core.fallback_logs}/#{Autoupdate::Core.name}.err"
      log_std = "#{Autoupdate::Core.fallback_logs}/#{Autoupdate::Core.name}.out"
    else
      puts <<~EOS
        #{Autoupdate::Core.logs} does not seem to be writable.
        You may with to `chown` it back to your user.
      EOS
    end

    # If someone has previously stopped the command assume when they start
    # it again they'd want to keep the same options & don't replace the script.
    # If you want to tweak prior-provided options the expected way is with the
    # delete command followed by the start command with new args.
    unless File.exist?(Autoupdate::Core.location/"updater")
      File.open(Autoupdate::Core.location/"updater", "w") { |sc| sc << script_contents }
      FileUtils.chmod 0555, Autoupdate::Core.location/"updater"
    end

    # There's no other valid reason for including numbers in the arguments
    # passed so we can roll with this method for determining interval. At
    # some point we should consider a less gross way of handling this though.
    if !ARGV.to_s.gsub(/[^\d]/, "").empty?
      interval = ARGV.to_s.gsub(/[^\d]/, "")
    else
      interval = "86400"
    end

    file = <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{Autoupdate::Core.name}</string>
        <key>Program</key>
        <string>#{Autoupdate::Core.location}/updater</string>
        <key>ProgramArguments</key>
        <array>
            <string>#{Autoupdate::Core.location}/updater</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>#{log_err}</string>
        <key>StandardOutPath</key>
        <string>#{log_std}</string>
        <key>StartInterval</key>
        <integer>#{interval}</integer>
      </dict>
      </plist>
    EOS

    # https://github.com/DomT4/homebrew-autoupdate/issues/10
    user_la = Pathname.new(Autoupdate::Core.plist).dirname
    unless user_la.exist?
      puts <<~EOS
        #{user_la} does not exist. Please create it first:
          mkdir -p #{user_la}
        You may need to use `sudo`.
      EOS
      exit 1
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
