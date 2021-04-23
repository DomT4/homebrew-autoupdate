# frozen_string_literal: true

module Autoupdate
  module_function

  def check_is_not_already_stopped
    return if Utils.popen_read("/bin/launchctl", "list").include?(Autoupdate::Core.name)

    odie <<~EOS
      Autoupdate is not currently running; cannot stop a command that is not running.
    EOS
  end

  def stop
    check_is_not_already_stopped

    quiet_system "/bin/launchctl", "unload", Autoupdate::Core.plist
    puts "Homebrew will no longer autoupdate."
  end
end
