module Autoupdate
  module_function

  def version
    puts <<-EOS.undent
      Version 2.2.0. Last Changed: Feb 2017
    EOS
  end
end
