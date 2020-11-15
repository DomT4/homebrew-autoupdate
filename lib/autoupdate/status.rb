module Autoupdate
  module_function

  def autoupdate_running?
    # Method from Homebrew.
    # https://github.com/Homebrew/brew/blob/c9c7f4/Library/Homebrew/utils/popen.rb
    Utils.popen_read("/bin/launchctl list").include?(Autoupdate::Core.name)
  end

  def autoupdate_installed_but_stopped?
    File.exist?(Autoupdate::Core.location/"brew_autoupdate") && !autoupdate_running?
  end

  def autoupdate_not_configured?
    !File.exist?(Autoupdate::Core.plist)
  end

  def status
    if autoupdate_running?
      puts "Autoupdate is installed and running."
    elsif autoupdate_installed_but_stopped?
      puts "Autoupdate is installed but stopped."
    elsif autoupdate_not_configured?
      puts "Autoupdate is not configured. Use `brew autoupdate --start` to begin."
    else
      puts <<~EOS
        Autoupdate cannot determine its status.
        Please feel free to file an issue with further information here:
          https://github.com/DomT4/homebrew-autoupdate/issues
      EOS
    end
  end
end
