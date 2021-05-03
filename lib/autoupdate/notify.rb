# frozen_string_literal: true

module Autoupdate
  module Notify
    module_function

    def notifier
      Formula["terminal-notifier"].opt_bin/"terminal-notifier" ||
        which("terminal-notifier") ||
        File.exist?("/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier") ||
        File.exist?(File.expand_path("~/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier"))
    end

    def path_to_notifier
      # This should allow notifications to work even if someone has
      # brew unlink'ed terminal-notifier.
      if File.executable?(Formula["terminal-notifier"].opt_bin/"terminal-notifier") ||
         (which("terminal-notifier") && File.executable?(notifier))
        File.path(File.expand_path(notifier))
      elsif File.exist?("/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier")
        "/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier"
      elsif File.exist?(File.expand_path("~/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier"))
        File.expand_path("~/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier")
      else
        false
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

    def notifier_app
      File.join(Autoupdate::Core.tap_dir, "notifier", "brew-autoupdate.app")
    end

    def new_notify
      "/usr/bin/open #{notifier_app}"
    end
  end
end
