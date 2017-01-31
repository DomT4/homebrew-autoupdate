require "fileutils"
require "pathname"

module Autoupdate
  brew = HOMEBREW_PREFIX/"bin/brew"
  plist = File.expand_path("~/Library/LaunchAgents/com.github.domt4.homebrew-autoupdate.plist")
  logs = File.expand_path("~/Library/Logs/com.github.domt4.homebrew-autoupdate")
  location = Pathname.new(File.expand_path("~/Library/Caches/com.github.domt4.homebrew-autoupdate"))

  if ARGV.empty? || ARGV.include?("--help") || ARGV.include?("-h")
    puts <<-EOS.undent
      Usage:
      --start = Start autoupdating every 24 hours.
      --stop = Stop autoupdating, but retain plist & logs.
      --delete = Cancel the autoupdate, delete the plist and logs.
      --upgrade = Also automatically upgrade your packages.
      --cleanup = Automatically cleanup old packages after upgrade.
      --version = Output this tool's current version.
    EOS
  end

  puts "Version 2.0.0. Last Changed: Jan 2017" if ARGV.include? "--version"

  if ARGV.include? "--start"
    if File.exist?(plist)
      puts <<-EOS.undent
        The command already appears to have been started.
        Please run `brew autoupdate --delete` and try again.
      EOS
      exit 1
    end

    auto_args = "update"
    # Spacing at start of lines is deliberate. Don't undo.
    if ARGV.include? "--upgrade"
      auto_args << " && #{brew} upgrade -v"
      auto_args << " && #{brew} cleanup" if ARGV.include? "--cleanup"
    end

    script_contents = <<-EOS.undent
      #!/bin/bash
      /bin/date && #{brew} #{auto_args}
    EOS
    FileUtils.mkpath(logs)
    FileUtils.mkpath(location)
    File.open(location/"updater", "w") { |sc| sc << script_contents }
    FileUtils.chmod 0555, location/"updater"

    file = <<-EOS.undent
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.github.domt4.homebrew-autoupdate</string>
        <key>Program</key>
        <string>#{location}/updater</string>
        <key>ProgramArguments</key>
        <array>
            <string>#{location}/updater</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>#{logs}/com.github.domt4.homebrew-autoupdate.err</string>
        <key>StandardOutPath</key>
        <string>#{logs}/com.github.domt4.homebrew-autoupdate.out</string>
        <key>StartInterval</key>
        <integer>86400</integer>
      </dict>
      </plist>
    EOS

    File.open(plist, "w") { |f| f << file }
    quiet_system "/bin/launchctl", "load", plist
    puts "Homebrew will now automatically update every 24 hours, or on system boot."
  end

  if ARGV.include? "--stop"
    quiet_system "/bin/launchctl", "unload", plist
    puts "Homebrew will no longer autoupdate."
  end

  if ARGV.include? "--delete"
    quiet_system "/bin/launchctl", "unload", plist
    FileUtils.rm_f plist
    FileUtils.rm_rf location
    FileUtils.rm_rf logs
    # Old logs location. Keep around for a bit so we're not littering.
    FileUtils.rm_f "#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.err"
    FileUtils.rm_f "#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.out"
    # Old plist name, adjusted for clarity of origin in version 2.0.0.
    FileUtils.rm_f File.expand_path("~/Library/LaunchAgents/homebrew.mxcl.autoupdate.plist")
    puts "Homebrew will no longer autoupdate and the plist has been deleted."
  end
end
