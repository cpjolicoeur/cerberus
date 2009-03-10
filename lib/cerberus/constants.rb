module Cerberus
  HOME = File.expand_path(ENV['CERBERUS_HOME'] || '~/.cerberus')
  CONFIG_FILE = "#{HOME}/config.yml"

  LOCK_WAIT = 30 * 60 #30 minutes

  VERSION = '0.4.5'
end
