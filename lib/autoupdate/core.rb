module Autoupdate
  module Core
    module_function

    def name
      "com.github.domt4.homebrew-autoupdate".freeze
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

    def location
      Pathname.new(File.expand_path("~/Library/Application Support/#{name}"))
    end
  end
end
