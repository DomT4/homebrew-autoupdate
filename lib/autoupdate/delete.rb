# frozen_string_literal: true

module Autoupdate
  module_function

  def delete
    # quiet_system("/bin/launchctl", "unload", Autoupdate::Core.plist, out: File::NULL, err: File::NULL)
    system("/bin/launchctl", "unload", Autoupdate::Core.plist, out: File::NULL, err: File::NULL)
    Autoupdate.cleanup

    puts "Homebrew will no longer autoupdate and the plist has been deleted."
  end
end
