# frozen_string_literal: true

require "shellwords"

module Autoupdate
  module Notify
    module_function

    def notifier_app
      File.join(Autoupdate::Core.tap_dir, "notifier", "brew-autoupdate.app")
    end

    def notifier_script
      File.join(Autoupdate::Core.tap_dir, "notifier", "notify.sh")
    end

    def command(mode:)
      [
        Shellwords.escape(notifier_script),
        "\"$status\"",
        "\"$run_log\"",
        Shellwords.escape(mode),
        Shellwords.escape(notifier_app),
      ].join(" ")
    end
  end
end
