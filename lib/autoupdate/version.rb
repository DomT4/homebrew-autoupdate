# frozen_string_literal: true

module Autoupdate
  module_function

  def generate_version_notes
    tapdir = Autoupdate::Core.tap_dir
    log = nil

    unless (tapdir/".git/shallow").exist?
      last_version = Utils.popen_read("git", "-C", tapdir, "log", "--oneline",
                                      "--grep=version: bump", "-n1", "--skip=1",
                                      "--no-merges",
                                      "--pretty=format:'%h'").delete("'").chomp

      current_version = Utils.popen_read("git", "-C", tapdir, "log", "--oneline",
                                         "--grep=version: bump", "-n1",
                                         "--no-merges",
                                         "--pretty=format:'%h'").delete("'").chomp

      log = Utils.popen_read("git", "-C", tapdir, "log", "--oneline", "--no-merges",
                             "#{last_version}..#{current_version}").chomp
    end

    return if log.nil?

    puts <<~EOS
      Changes since last version:

      #{log}
    EOS
  end

  def version
    puts <<~EOS
      Version 3.3.0. Last Changed: May 2025

    EOS
    generate_version_notes
  end
end
