require 'cerberus/constants'
require 'cerberus/utils'
require 'erb'

module Cerberus
  class Config
    def initialize(app_name = nil, cli_options = {})
      @config = HashWithIndifferentAccess.new
      if app_name
        merge!(YAML.load(ERB.new(IO.read(CONFIG_FILE)).result)) if test(?f, CONFIG_FILE)
        merge!(YAML.load(ERB.new(IO.read(HOME + "/config/#{app_name}.yml")).result))
      end
      merge!(cli_options)
    end

    def [](*path)
      c = @config
      path.each{|p|
        c = c[p]
        return if c.nil?
      }
      c
    end

    def merge!(hash, overwrite = true)
      if overwrite
        @config.deep_merge!(hash)
      else
        d = HashWithIndifferentAccess.new(hash)
        d.deep_merge!(@config)
        @config = d
      end
    end

    def inspect
      @config.inspect
    end

    private
    def symbolize_hash(hash)
      hash.each_pair{|k,v|
        if v === Hash
          hash[k] = HashWithIndifferentAccess.new(symbolize_hash(v))
        end
      }
    end
  end
end