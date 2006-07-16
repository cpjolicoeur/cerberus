module Cerberus
  HOME = File.expand_path(ENV['CERBERUS_HOME'] || '~/.cerberus')
  CONFIG_FILE = "#{HOME}/config.yml"
end