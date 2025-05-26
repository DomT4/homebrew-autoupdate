# frozen_string_literal: true

module Autoupdate
  module_function

  def logs(follow: false, lines: 10)
    log_file = File.join(Autoupdate::Core.logs, "#{Autoupdate::Core.name}.out")
    fallback_log_file = File.join(Autoupdate::Core.fallback_logs, "#{Autoupdate::Core.name}.out")

    file_to_read = if File.exist?(log_file)
      log_file
    elsif File.exist?(fallback_log_file)
      fallback_log_file
    else
      puts "No autoupdate log file found at `#{log_file}` or fallback `#{fallback_log_file}`."
      return
    end

    if follow
      system("tail", "-n", lines.to_s, "-f", file_to_read)
    else
      system("tail", "-n", lines.to_s, file_to_read)
    end
  end
end
