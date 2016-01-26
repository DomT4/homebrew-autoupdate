#!/usr/bin/env ruby -w

require "fileutils"
require "open-uri"

module Homebrew
  def autoupdate
    path = File.expand_path("~/Library/LaunchAgents/homebrew.mxcl.autoupdate.plist")

    if ARGV.empty? || ARGV.include?("--help") || ARGV.include?("-h")
      puts <<-EOS.undent
        Usage:
        --start [seconds] = Start autoupdating every 24 hours or with a specified time interval.
        --stop = Stop autoupdating, but retain plist & logs.
        --delete = Cancel the autoupdate, delete the plist and logs.
        --upgrade = Also automatically upgrade your packages.
        --version = Output this tool's current version.
      EOS
    end

    if ARGV.include? "--version"
      puts "Version 1.1.0, July 2015"
    end

    if ARGV.include? "--start"
      auto_args = "#{HOMEBREW_PREFIX}/bin/brew update"
      # Spacing at start of line is deliberate. Don't undo.
      auto_args << " && #{HOMEBREW_PREFIX}/bin/brew upgrade -v" if ARGV.include? "--upgrade"
      
      ARGV[1].nil? ? time_interval = 86400 : time_interval = ARGV[1].to_i

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
          <integer>#{time_interval}</integer>
        </dict>
        </plist>
      EOS

      File.open(path, "w") { |f| f << file }
      quiet_system "/bin/launchctl", "load", path
      puts "Homebrew will now automatically update every #{time_interval} seconds, or on system boot."
    end

    if ARGV.include? "--stop"
      quiet_system "/bin/launchctl", "unload", path
      puts "Homebrew will no longer autoupdate."
    end

    if ARGV.include? "--delete"
      quiet_system "/bin/launchctl", "unload", path
      rm_f path
      rm_f "#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.err"
      rm_f "#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.out"
      puts "Homebrew will no longer autoupdate and the plist has been deleted."
    end
  end
end

Homebrew::autoupdate