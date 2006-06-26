module Cerberus
  module Utils
    def say(info)
      puts info
      exit 1
    end

    def os
      case Config::CONFIG["arch"]
      when /(dos|win32)/
        :windows
      else
        :unix
      end
    end
  end
end