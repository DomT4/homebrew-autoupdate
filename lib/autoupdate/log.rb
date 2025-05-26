# frozen_string_literal: true

module Autoupdate
  module_function

  def log(follow: false)
    log_file = File.expand_path("~/Library/Logs/Homebrew/autoupdate.log")
    unless File.exist?(log_file)
      puts "No autoupdate log file found at #{log_file}."
      return
    end

    if follow
      File.open(log_file) do |file|
        file.seek(0, IO::SEEK_END)
        loop do
          changes = file.read
          if changes
            print changes
          else
            sleep 1
          end
        end
      end
    else
      puts File.read(log_file)
    end
  end
end
