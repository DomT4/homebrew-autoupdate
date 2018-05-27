module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.7.0. Last Changed: May 2018
    EOS
  end
end
