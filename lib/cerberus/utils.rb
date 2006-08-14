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

alias __exec `
def `(cmd)
  begin
    __exec(cmd)
  rescue Exception => e           
    raise "Unable to execute: #{cmd}"
  end
end

class Hash
  def deep_merge!(second)
    second.each_pair do |k,v|
      if self[k].is_a?(Hash) and second[k].is_a?(Hash)
        self[k].deep_merge!(second[k])
      else
        self[k] = second[k]
      end
    end
  end
end