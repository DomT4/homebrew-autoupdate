module Autoupdate
  module_function

  def stop
    quiet_system "/bin/launchctl", "unload", Autoupdate::Core.plist
    puts "Homebrew will no longer autoupdate."
  end
end
