module Autoupdate
  module_function

  def version
    puts <<-EOS.undent
      Version 2.1.0. Last Changed: Jan 2017
    EOS
  end
end
