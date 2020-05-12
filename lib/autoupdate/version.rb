module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.9.0. Last Changed: May 2020
    EOS
  end
end
