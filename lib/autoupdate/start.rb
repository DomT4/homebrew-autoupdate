module Autoupdate
  module_function

  def start
    if File.exist?(Autoupdate::Core.plist)
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
    File.open(Autoupdate::Core.location/"updater", "w") { |sc| sc << script_contents }
    FileUtils.chmod 0555, Autoupdate::Core.location/"updater"

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
        <string>#{Autoupdate::Core.logs}/#{Autoupdate::Core.name}.err</string>
        <key>StandardOutPath</key>
        <string>#{Autoupdate::Core.logs}/#{Autoupdate::Core.name}.out</string>
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
