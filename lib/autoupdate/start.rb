module Autoupdate
  module_function

  def start
    # Method from Homebrew.
    # https://github.com/Homebrew/brew/blob/c9c7f4/Library/Homebrew/utils/popen.rb
    if Utils.popen_read("/bin/launchctl list").include?(Autoupdate::Core.name)
      puts <<-EOS.undent
        The command already appears to have been started.
        Please run `brew autoupdate --delete` and try again.
      EOS
      exit 1
    end

    auto_args = "update"
    # Spacing at start of lines is deliberate. Don't undo.
    if ARGV.include? "--upgrade"
      auto_args << " && #{Autoupdate::Core.brew} upgrade -v"
      auto_args << " && #{Autoupdate::Core.brew} cleanup" if ARGV.include? "--cleanup"
    end

    script_contents = <<-EOS.undent
      #!/bin/bash
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
      puts <<-EOS.undent
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

    file = <<-EOS.undent
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
        <integer>86400</integer>
      </dict>
      </plist>
    EOS

    File.open(Autoupdate::Core.plist, "w") { |f| f << file }
    quiet_system "/bin/launchctl", "load", Autoupdate::Core.plist
    puts "Homebrew will now automatically update every 24 hours, or on system boot."
  end
end
