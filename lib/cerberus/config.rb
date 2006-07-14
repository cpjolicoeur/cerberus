require 'rubygems'
require 'active_support'

require 'cerberus/constants'

module Cerberus
  class Config
    def initialize(app_name, cli_options = {})
      @config = HashWithIndifferentAccess.new
      if app_name
        @config.merge!(YAML.load(IO.read(CONFIG_FILE))) if test(?f, CONFIG_FILE)
        @config.merge!(YAML.load(IO.read(HOME + "/config/#{app_name}.yml")))
      end
      @config.merge!(cli_options)
    end

    def [](name)
      @config[name]
    end
  end
end