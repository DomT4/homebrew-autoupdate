# frozen_string_literal: true

module Autoupdate
  module_function

  def log(follow: false)
    log_file = "#{Autoupdate::Core.logs}/#{Autoupdate::Core.name}.log"
    fallback_log_file = "#{Autoupdate::Core.fallback_logs}/#{Autoupdate::Core.name}.log"

    if File.exist?(log_file)
      file_to_read = log_file
    elsif File.exist?(fallback_log_file)
      file_to_read = fallback_log_file
    else
      puts "No autoupdate log file found at #{log_file} or fallback #{fallback_log_file}."
      return
    end

    if follow
      File.open(file_to_read) do |file|
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
      puts File.read(file_to_read)
    end
  end
end
