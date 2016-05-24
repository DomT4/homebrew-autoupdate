#!/usr/bin/env ruby -w

require "fileutils"
require "utils"

module Autoupdate
  plist = File.expand_path("~/Library/LaunchAgents/homebrew.mxcl.autoupdate.plist")
  brew = HOMEBREW_PREFIX/"bin/brew"

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

  if ARGV.include? "--version"
    puts "Version 1.2.0, May 2016"
  end

  if ARGV.include? "--start"
    auto_args = "#{brew} update"
    # Spacing at start of lines is deliberate. Don't undo.
    if ARGV.include? "--upgrade"
      auto_args << " && #{brew} upgrade -v"
      auto_args << " && #{brew} cleanup" if ARGV.include? "--cleanup"
    end

    file = <<-EOS.undent
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>homebrew.mxcl.autoupdate</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/sh</string>
            <string>-c</string>
            <string>/bin/date && #{auto_args}</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.err</string>
        <key>StandardOutPath</key>
        <string>#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.out</string>
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
    FileUtils.rm_f "#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.err"
    FileUtils.rm_f "#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.out"
    puts "Homebrew will no longer autoupdate and the plist has been deleted."
  end
end
