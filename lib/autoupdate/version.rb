module Autoupdate
  module_function

  def version
    puts <<~EOS
      Version 2.5.3. Last Changed: March 2018
    EOS
  end
end
