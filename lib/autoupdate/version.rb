module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.5.1. Last Changed: November 2017
    EOS
  end
end
