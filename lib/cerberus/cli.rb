require 'cerberus/manager'
require 'cerberus/utils'

module Cerberus
  class CLI     
    include Cerberus::Utils

    def initialize(*args)
      say HELP if args.empty?

      case command = args[0]
      when 'add'
        path = args[1] || Dir.pwd
        
        Cerberus::Add.new(path,
          :application_name => ENV['APPLICATION_NAME'],
          :recipients       => ENV['RECIPIENTS']
        )
      when 'build'
        say HELP if args.length < 2

        build = Cerberus::Build.new(args[1],
          :task_name        => ENV['RAKE_TASK'] || '',
          :bin_path         => ENV['BIN_PATH']  || ("/usr/local/bin/" if os() == :unix),

          :application_name => args[1], 
          :recipients       => ENV['RECIPIENTS'], 
          :sender           => ENV['SENDER']
        )

        build.run
      else
        say HELP
      end
    end
  end

  HELP = %{
    Cerberus is a Continuous Integration tool that could be run from commad line.

    Usage:
      cerberus add <URL>      --- add project from svn repository to list watched of applications
      cerberus add <PATH>     --- add project from local path to list of watched applications
      cerberus build <APPLICATION_NAME>  --- build watched application
  }.gsub("\n    ","\n")
end