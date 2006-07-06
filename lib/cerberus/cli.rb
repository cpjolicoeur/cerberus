require 'cerberus/manager'
require 'cerberus/utils'
require 'cerberus/version'

module Cerberus
  class CLI     
    include Cerberus::Utils

    def initialize(*args)
      say HELP if args.empty?

      command = args[0]
      say HELP unless %w(add build).include?(command)

      case command
      when 'add'
        path = args[1] || Dir.pwd
        
        command = Cerberus::Add.new(path,
          :application_name => ENV['APPLICATION_NAME'],
          :recipients       => ENV['RECIPIENTS']
        )

        command.run
      when 'build'
        say HELP if args.length < 2

        command = Cerberus::Build.new(args[1],
          :task_name        => ENV['RAKE_TASK'] || '',
          :bin_path         => ENV['BIN_PATH']  || ("/usr/local/bin/" if os() == :unix),

          :application_name => args[1], 
          :recipients       => ENV['RECIPIENTS'], 
          :sender           => ENV['SENDER']
        )

        command.run
      end
    end
  end

  HELP = %{
    Cerberus is a Continuous Integration tool that could be run from commad line.

    Usage:
      cerberus add <URL>      --- add project from svn repository to list watched of applications
      cerberus add <PATH>     --- add project from local path to list of watched applications
      cerberus build <APPLICATION_NAME>  --- build watched application

    Version #{Cerberus::VERSION::STRING}
  }.gsub("\n    ","\n")
end