module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.7.1. Last Changed: November 2018
    EOS
  end
end
