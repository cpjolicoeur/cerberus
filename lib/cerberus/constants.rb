require 'active_support'

module Cerberus
  HOME = File.expand_path(ENV['CERBERUS_HOME'] || '~/.cerberus')
  CONFIG_FILE = "#{HOME}/config.yml"

  LOCK_WAIT = 30.minutes
end
