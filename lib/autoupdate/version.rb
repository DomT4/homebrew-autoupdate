module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.12.0. Last Changed: Feb 2021
    EOS
  end
end
