# frozen_string_literal: true

require "plist"

module Autoupdate
  module_function

  def autoupdate_running?
    # Method from Homebrew.
    # https://github.com/Homebrew/brew/blob/c9c7f4/Library/Homebrew/utils/popen.rb
    Utils.popen_read("/bin/launchctl", "list").include?(Autoupdate::Core.name)
  end

  def autoupdate_not_configured?
    !File.exist?(Autoupdate::Core.plist)
  end

  def date_of_last_modification
    if File.exist?(Autoupdate::Core.location/"brew_autoupdate")
      birth = File.birthtime(Autoupdate::Core.location/"brew_autoupdate")
      formatted_string = birth.strftime("%F")
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
    running = autoupdate_running?
    installed = File.exist?(Autoupdate::Core.location/"brew_autoupdate")

    if running || installed
      state = running ? "running" : "stopped"
      puts "Autoupdate is installed and #{state}."
      puts
      puts "Initialised: #{date_of_last_modification}"
      puts configuration_summary
      puts
      puts autoupdate_inadvisably_old_message if autoupdate_inadvisably_old_message
    elsif autoupdate_not_configured?
      puts "Autoupdate is not configured. Use `brew autoupdate start` to begin."
    else
      puts <<~EOS
        Autoupdate cannot determine its status.
        Please feel free to file an issue with further information here:
        https://github.com/DomT4/homebrew-autoupdate/issues
      EOS
    end
  end

  def configuration_summary
    plist = Plist.parse_xml(Autoupdate::Core.plist, marshal: false) || {}
    interval = plist["StartInterval"]
    script = updater_script
    details = []

    details << "Schedule: every #{Autoupdate::Interval.describe(interval.to_i)} (#{interval} seconds)" if interval
    details << "Run at login: #{plist["RunAtLoad"] ? "yes" : "no"}"
    details << "Upgrade: #{upgrade_summary(script)}"
    details << "Cleanup: #{script.include?("#{Autoupdate::Core.brew} cleanup") ? "yes" : "no"}"
    details << "AC power only: #{script.include?("/usr/bin/pmset -g ps") ? "yes" : "no"}"
    details << "Greedy cask upgrades: yes" if script.include?("upgrade --cask -v --greedy")
    details << "GUI sudo prompt: yes" if script.include?("brew_autoupdate_sudo_gui")
    details << "Notifications: #{script.include?("/usr/bin/open -g") ? "yes" : "no"}"
    details << "Logs: #{plist["StandardOutPath"]}" if plist["StandardOutPath"]

    details.join("\n")
  rescue => e
    "Configuration: unable to read (#{e.message})"
  end

  def updater_script
    File.read(Autoupdate::Core.location/"brew_autoupdate")
  rescue Errno::ENOENT
    ""
  end

  def upgrade_summary(script)
    return "top-level formulae only" if script.include?("brew_autoupdate_leaves")

    selected_upgrade = script.lines.find do |line|
      line.include?("#{Autoupdate::Core.brew} upgrade -v")
    end
    if selected_upgrade
      packages = selected_upgrade.split(/\s+upgrade\s+-v(?:\s+--greedy)?\s+/, 2).last&.strip
      packages = packages&.split(" && ", 2)&.first
      return "selected packages (#{packages})" if packages.present?
    end

    formulae = script.include?("#{Autoupdate::Core.brew} upgrade --formula")
    casks = script.include?("#{Autoupdate::Core.brew} upgrade --cask")
    return "formulae and casks" if formulae && casks
    return "formulae only" if formulae
    return "casks only" if casks

    "no"
  end
end
