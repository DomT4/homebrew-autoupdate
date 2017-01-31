require "fileutils"
require "pathname"

module Autoupdate
  module_function

  @brew = HOMEBREW_PREFIX/"bin/brew"
  @name = "com.github.domt4.homebrew-autoupdate"
  @plist = File.expand_path("~/Library/LaunchAgents/#{@name}.plist")
  @logs = File.expand_path("~/Library/Logs/#{@name}")
  @location = Pathname.new(File.expand_path("~/Library/Application Support/#{@name}"))

  def cleanup
    # Remove the old locations after a few months once it's safe to assume most
    # existing users will have executed this command since the changes.
    old_logs = Dir["#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.*"]
    old_plist = File.expand_path("~/Library/LaunchAgents/homebrew.mxcl.autoupdate.plist")
    old_location = File.expand_path("~/Library/Caches/#{@name}")
    FileUtils.rm_f old_logs
    FileUtils.rm_f old_plist
    FileUtils.rm_rf old_location

    FileUtils.rm_f @plist
    FileUtils.rm_rf @location
    FileUtils.rm_rf @logs
  end

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

  puts "Version 2.1.0. Last Changed: Jan 2017" if ARGV.include? "--version"

  if ARGV.include? "--start"
    if File.exist?(@plist)
      puts <<-EOS.undent
        The command already appears to have been started.
        Please run `brew autoupdate --delete` and try again.
      EOS
      exit 1
    end

    auto_args = "update"
    # Spacing at start of lines is deliberate. Don't undo.
    if ARGV.include? "--upgrade"
      auto_args << " && #{@brew} upgrade -v"
      auto_args << " && #{@brew} cleanup" if ARGV.include? "--cleanup"
    end

    script_contents = <<-EOS.undent
      #!/bin/bash
      /bin/date && #{@brew} #{auto_args}
    EOS
    FileUtils.mkpath(@logs)
    FileUtils.mkpath(@location)
    File.open(@location/"updater", "w") { |sc| sc << script_contents }
    FileUtils.chmod 0555, @location/"updater"

    file = <<-EOS.undent
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{@name}</string>
        <key>Program</key>
        <string>#{@location}/updater</string>
        <key>ProgramArguments</key>
        <array>
            <string>#{@location}/updater</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>#{@logs}/#{@name}.err</string>
        <key>StandardOutPath</key>
        <string>#{@logs}/#{@name}.out</string>
        <key>StartInterval</key>
        <integer>86400</integer>
      </dict>
      </plist>
    EOS

    File.open(@plist, "w") { |f| f << file }
    quiet_system "/bin/launchctl", "load", @plist
    puts "Homebrew will now automatically update every 24 hours, or on system boot."
  end

  if ARGV.include? "--stop"
    quiet_system "/bin/launchctl", "unload", @plist
    puts "Homebrew will no longer autoupdate."
  end

  if ARGV.include? "--delete"
    quiet_system "/bin/launchctl", "unload", @plist
    Autoupdate.cleanup

    puts "Homebrew will no longer autoupdate and the plist has been deleted."
  end
end
