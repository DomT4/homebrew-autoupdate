module Autoupdate
  module_function

  def cleanup
    fallback_logs = Dir[File.join(Autoupdate::Core.fallback_logs, "#{Autoupdate::Core.name}.*")]

    FileUtils.rm_f fallback_logs
    FileUtils.rm_f Autoupdate::Core.plist
    FileUtils.rm_rf Autoupdate::Core.location
    FileUtils.rm_rf Autoupdate::Core.logs
  end
end
