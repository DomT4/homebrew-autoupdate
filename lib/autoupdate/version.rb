module Autoupdate
  module_function

  def version
    puts <<-EOS.undent
      Version 2.3.2. Last Changed: Feb 2017
    EOS
  end
end
