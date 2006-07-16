require 'yaml'

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

    def dump_yml(file, what, overwrite = true)
      if overwrite or not File.exists?(file)
        FileUtils.mkpath(File.dirname(file))
        File.open(file, 'w') {|f| YAML::dump(what, f) } 
      end
    end

    def load_yml(file_name, default = {})
      File.exists?(file_name) ? YAML::load(IO.read(file_name)) : default
    end
  end
end