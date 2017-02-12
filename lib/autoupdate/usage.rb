module Autoupdate
  module_function

  def usage
    <<-EOS.undent
      Usage:
      --start = Start autoupdating every 24 hours.
      --stop = Stop autoupdating, but retain plist & logs.
      --delete = Cancel the autoupdate, delete the plist and logs.
      --upgrade = Also automatically upgrade your packages.
      --cleanup = Automatically cleanup old packages after upgrade.
      --version = Output this tool's current version.
    EOS
  end
end
