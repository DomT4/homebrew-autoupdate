module Autoupdate
  module_function

  def delete
    quiet_system "/bin/launchctl", "unload", Autoupdate::Core.plist
    Autoupdate.cleanup

    puts "Homebrew will no longer autoupdate and the plist has been deleted."
  end
end
