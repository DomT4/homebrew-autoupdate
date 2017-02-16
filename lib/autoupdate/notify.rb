module Autoupdate
  module Notify
    module_function

    def notifier
      which("terminal-notifier") ||
        File.exist?("/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier") ||
        File.exist?(File.expand_path("~/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier"))
    end

    def path_to_notifier
      if notifier && File.executable?(notifier)
        File.path(File.expand_path(notifier))
      end
    end

    def notifier_arguments
      # Separating these out is kind of pointless but does
      # ensure this file isn't hundreds of characters wide.
      title = "-title '🍺 brew-autoupdate'"
      message = "-message 'Homebrew has been automatically updated.'"
      group = "-group 'com.github.domt4.homebrew-autoupdate'"

      "#{title} #{message} #{group}"
    end

    def notify
      "#{path_to_notifier} #{notifier_arguments}"
    end
  end
end
