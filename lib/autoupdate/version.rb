module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.11.0. Last Changed: November 2020
    EOS
  end
end
