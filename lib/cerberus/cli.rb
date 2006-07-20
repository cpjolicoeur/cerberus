require 'cerberus/manager'
require 'cerberus/utils'
require 'cerberus/version'
require 'cerberus/constants'

module Cerberus
  class CLI     
    include Cerberus::Utils

    def initialize(*args)
      say HELP if args.empty?

      command = args.shift
      say HELP unless %w(add build).include?(command)

      cli_options = extract_options(args)

      case command
      when 'add'
        path = args.shift || Dir.pwd
        
        command = Cerberus::Add.new(path, cli_options)
        command.run
      when 'build'
        say HELP if args.empty?

        application_name  = args.shift

        command = Cerberus::Build.new(application_name, cli_options)
        command.run
      when 'buildall'
        command = Cerberus::BuildAll.new(cli_options)
        command.run
      end
    end

    private 
    def extract_options(args)
      result = {}
      args_copy = args.dup
      args_copy.each do |arg|
        if arg =~ /^(\w+)=(.*)$/
          result[$1.downcase.to_sym] = $2
          args.delete(arg)
        end
      end

      result
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