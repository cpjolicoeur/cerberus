require 'yaml'

module Cerberus
  module Utils
    def say(msg)
      STDERR << msg
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
        return true
      rescue
        return false
      end
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

class HashWithIndifferentAccess < Hash
  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
  end
 
  def default(key)
    self[key.to_s] if key.is_a?(Symbol)
  end  

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
  alias_method :regular_update, :update unless method_defined?(:regular_update)
  
  def []=(key, value)
    regular_writer(convert_key(key), convert_value(value))
  end

  def update(other_hash)
    other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) }
    self
  end
  
  alias_method :merge!, :update

  def key?(key)
    super(convert_key(key))
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  def fetch(key, *extras)
    super(convert_key(key), *extras)
  end

  def values_at(*indices)
    indices.collect {|key| self[convert_key(key)]}
  end

  def dup
    HashWithIndifferentAccess.new(self)
  end
  
  def merge(hash)
    self.dup.update(hash)
  end

  def delete(key)
    super(convert_key(key))
  end
    
  protected
    def convert_key(key)
      key.kind_of?(Symbol) ? key.to_s : key
    end
    def convert_value(value)
      value.is_a?(Hash) ? HashWithIndifferentAccess.new(value) : value
    end
end


class IO
  def self.write(filename, str)
    File.open(filename, 'w'){|f| f.write str}
  end
end
