module Autoupdate
  module_function

  def cleanup
    # Remove the old locations after a few months once it's safe to assume most
    # existing users will have executed this command since the changes.
    old_logs = Dir["#{HOMEBREW_PREFIX}/var/log/homebrew.mxcl.autoupdate.*"]
    fallback_logs = Dir[File.join(Autoupdate::Core.fallback_logs, "#{Autoupdate::Core.name}.*")]
    old_plist = File.expand_path("~/Library/LaunchAgents/homebrew.mxcl.autoupdate.plist")
    old_location = File.expand_path("~/Library/Caches/#{Autoupdate::Core.name}")

    FileUtils.rm_f old_logs
    FileUtils.rm_f fallback_logs
    FileUtils.rm_f old_plist
    FileUtils.rm_rf old_location

    FileUtils.rm_f Autoupdate::Core.plist
    FileUtils.rm_rf Autoupdate::Core.location
    FileUtils.rm_rf Autoupdate::Core.logs
  end
end
