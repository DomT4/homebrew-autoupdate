# frozen_string_literal: true

module Autoupdate
  module Core
    module_function

    def name
      "com.github.domt4.homebrew-autoupdate"
    end

    def plist
      File.expand_path("~/Library/LaunchAgents/#{name}.plist")
    end

    def brew
      HOMEBREW_PREFIX/"bin/brew"
    end

    def logs
      File.expand_path("~/Library/Logs/#{name}")
    end

    def fallback_logs
      File.expand_path("..", logs)
    end

    def location
      Pathname.new(File.expand_path("~/Library/Application Support/#{name}"))
    end

    def tap_dir
      origin = Tap.names.join(" ").match(%r{(domt4|homebrew)/autoupdate})[1]
      Pathname.new(File.join(HOMEBREW_LIBRARY, "Taps", origin, "homebrew-autoupdate"))
    end

    def command_upgrade
      " && #{Autoupdate::Core.brew} upgrade --formula -v"
    end

    def command_cask(greedy)
      greedy_argument = greedy ? " --greedy" : ""
      " && #{Autoupdate::Core.brew} upgrade --cask -v#{greedy_argument}"
    end

    def command_cleanup
      " && #{Autoupdate::Core.brew} cleanup"
    end

    def command_sudo
      "export SUDO_ASKPASS='#{Autoupdate::Core.location/"brew_autoupdate_sudo_gui"}'"
    end
  end
end
