module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.8.0. Last Changed: March 2019
    EOS
  end
end
