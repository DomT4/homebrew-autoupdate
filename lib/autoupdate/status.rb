# frozen_string_literal: true

module Autoupdate
  module_function

  def autoupdate_running?
    # Method from Homebrew.
    # https://github.com/Homebrew/brew/blob/c9c7f4/Library/Homebrew/utils/popen.rb
    Utils.popen_read("/bin/launchctl", "list").include?(Autoupdate::Core.name)
  end

  def autoupdate_installed_but_stopped?
    File.exist?(Autoupdate::Core.location/"brew_autoupdate") && !autoupdate_running?
  end

  def autoupdate_not_configured?
    !File.exist?(Autoupdate::Core.plist)
  end

  def date_of_last_modification
    if File.exist?(Autoupdate::Core.location/"brew_autoupdate")
      birth = File.birthtime(Autoupdate::Core.location/"brew_autoupdate").to_s
      date = Date.parse(birth)
      formatted_string = date.strftime("%D")
    else
      formatted_string = "Unable to determine date of command invocation. Please report this."
    end
    formatted_string
  end

  def autoupdate_inadvisably_old_message
    creation = File.birthtime(Autoupdate::Core.location/"brew_autoupdate").to_date
    days_old = (Date.today - creation).to_i

    return if days_old < 90

    <<~EOS
      Autoupdate has been running for more than 90 days. Please consider
      periodically deleting and re-starting this command to ensure the
      latest features are enabled for you.
    EOS
  end

  def status
    if autoupdate_running?
      puts <<~EOS
        Autoupdate is installed and running.

        Autoupdate was initialised on #{date_of_last_modification}.
        \n#{autoupdate_inadvisably_old_message}
      EOS
    elsif autoupdate_installed_but_stopped?
      puts <<~EOS
        Autoupdate is installed but stopped.

        Autoupdate was initialised on #{date_of_last_modification}.
        \n#{autoupdate_inadvisably_old_message}
      EOS
    elsif autoupdate_not_configured?
      puts "Autoupdate is not configured. Use `brew autoupdate start` to begin."
    else
      puts <<~EOS
        Autoupdate cannot determine its status.
        Please feel free to file an issue with further information here:
        https://github.com/Homebrew/homebrew-autoupdate/issues
      EOS
    end
  end
end
