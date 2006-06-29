module Cerberus
  module Utils
    def say(info)
      puts info
      exit 1
    end

    def os
      case RUBY_PLATFORM
      when /mswin/
        :windows
      else
        :unix
      end
    end

    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(os == :windows ? 'NUL:' : '/dev/null')
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end
  end
end