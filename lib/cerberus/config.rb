require 'rubygems'
require 'active_support'

require 'cerberus/constants'
require 'cerberus/utils'

module Cerberus
  class Config
    def initialize(app_name = nil, cli_options = {})
      @config = HashWithIndifferentAccess.new
      if app_name
        merge!(YAML.load(IO.read(CONFIG_FILE))) if test(?f, CONFIG_FILE)
        merge!(YAML.load(IO.read(HOME + "/config/#{app_name}.yml")))
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

    def merge!(hash)          
      @config.deep_merge!(hash)
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