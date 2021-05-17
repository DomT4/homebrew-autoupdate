# frozen_string_literal: true

module Autoupdate
  module_function

  def cleanup
    log_files = Dir[File.join(Autoupdate::Core.fallback_logs, "**/#{Autoupdate::Core.base_name}.out")] |
                Dir[File.join(Autoupdate::Core.fallback_logs, "**/#{Autoupdate::Core.name}.out")]
    logs = Autoupdate::Core.logs

    FileUtils.rm_f log_files
    FileUtils.rm_f Autoupdate::Core.plist
    FileUtils.rm_rf Autoupdate::Core.location
    FileUtils.rmdir logs if File.exist?(logs) && Dir["#{logs}/*"].empty?
  end
end
