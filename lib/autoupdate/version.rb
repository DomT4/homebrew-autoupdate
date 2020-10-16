module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.10.0. Last Changed: October 2020
    EOS
  end
end
