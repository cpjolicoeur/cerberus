require 'manager'

module Cerberus
  module CLI
    def self.run(args)
      command = args[0]

      fail 'Please specify command (add,run)' unless command

      case command
        when 'add'
          Cerberus::Manager.add!(Dir.pwd)
        when 'run'
          Cerberus::Manager.run!(ARGV[1])
        else
          fail "Do not know what to do with command '#{command}'"
      end

    end
  end
end

