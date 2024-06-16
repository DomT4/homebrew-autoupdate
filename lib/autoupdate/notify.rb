# frozen_string_literal: true

module Autoupdate
  module Notify
    module_function

    def notifier_app
      File.join(Autoupdate::Core.tap_dir, "notifier", "brew-autoupdate.app")
    end

    def new_notify
      # The `-g` flag causes the app to launch in the background,
      # so that the focus is not removed from the current window.
      # https://github.com/Homebrew/homebrew-autoupdate/issues/71
      "/usr/bin/open -g #{notifier_app}"
    end
  end
end
