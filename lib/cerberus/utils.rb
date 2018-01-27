require 'yaml'

# Load in vendor libraries
for dir in Dir[File.join(File.dirname(__FILE__), '..', 'vendor', '*')]
  $: << File.join(dir, 'lib')
end

module Cerberus
  module Utils
    def say(msg)
      STDERR << msg << "\n"
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
      if overwrite or not File.exist?(file)
        FileUtils.mkpath(File.dirname(file))
        File.open(file, 'w') { |f| YAML::dump(what, f) }
      end
    end

    def load_yml(file_name, default = {})
      File.exist?(file_name) ? YAML::load(IO.read(file_name)) : default
    end

    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end

    def exec_successful?(cmd)
      begin
        `#{cmd}`
        return true if $?.exitstatus == 0
      rescue
        # if anything bad happens, return false
      end
      return false
    end

    def interpret_state(state, with_default = true)
      case
      when state == 'all'
        [:setup, :successful, :revival, :broken, :failed]
      when state == 'none'
        []
      when state == 'default' && with_default
        [:setup, :revival, :broken, :failed] #the same as 'all' except successful
      else
        state.scan(/\w+/).map { |s| s.to_sym }
      end
    end
  end
end

include Cerberus::Utils

alias __exec `

def `(cmd)
  begin
    __exec(cmd)
  rescue Exception => e
    raise "Unable to execute #{cmd}: #{e}"
  end
end

class Hash
  def deep_merge!(second)
    second.each_pair do |k, v|
      if self[k].is_a?(Hash) and second[k].is_a?(Hash)
        self[k].deep_merge!(second[k])
      else
        self[k] = second[k]
      end
    end
  end
end

class String
  def cron_match?(number)
    return false if not number.is_a?(Integer)
    return true if self == "*"
    parts = self.split(",")
    parts.each do |p|
      match = p.match(/(\d+|\*)-?(\d+)?(\/(\d+))?$/)
      return false if not match
      if not match[2]
        if match[1] == "*" and match[4]
          return true if number % match[4].to_i == 0
        end
        return true if match[1].to_i == number
      else
        range = (match[1].to_i)..(match[2].to_i)
        if not match[3]
          return true if range.include?(number)
        else
          range.each do |r|
            if (r - range.first) % match[4].to_i == 0
              return true if r == number
            end
          end
        end
      end
    end
    return false
  end
end
