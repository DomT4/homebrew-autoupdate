module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.4.1. Last Changed: October 2017
    EOS
  end
end
