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
      if Tap.fetch("homebrew/homebrew-autoupdate").path.exist?
        origin = "Homebrew"
      else
        origin = "domt4"
      end
        
      Pathname.new(File.join(HOMEBREW_LIBRARY, "Taps", origin, "homebrew-autoupdate"))
    end
  end
end
