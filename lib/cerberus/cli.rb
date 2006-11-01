require 'cerberus/manager'
require 'cerberus/utils'
require 'cerberus/constants'

module Cerberus
  class CLI     
    include Cerberus::Utils

    def initialize(*args)
      say HELP if args.empty?

      command = args.shift
      say HELP unless %w(add build buildall).include?(command)

      cli_options = extract_options(args)

      case command
      when 'add'
        path = args.shift || Dir.pwd
        
        command = Cerberus::AddCommand.new(path, cli_options)
        command.run
      when 'build'
        say HELP if args.empty?

        application_name  = args.shift

        command = Cerberus::BuildCommand.new(application_name, cli_options)
        command.run
      when 'buildall'
        command = Cerberus::BuildAllCommand.new(cli_options)
        command.run
      end
    end

    private 
    def extract_options(args)
      result = {}
      args_copy = args.dup
      args_copy.each do |arg|
        case arg
        when /^(\w+)=(.*)$/
          result[$1.downcase.to_sym] = $2
          args.delete(arg)
        when '--force'
          result[:force] = true
          args.delete(arg)
        end
      end

      result
    end
  end

  HELP = %{
    Cerberus is a simple Continuous Integration tool for Ruby projects that run from command-line interface.

    Usage:
      cerberus add <URL>      --- add project from svn repository to list watched of applications
      cerberus add <PATH>     --- add project from local path to list of watched applications
      cerberus build <APPLICATION_NAME>  --- build watched application
      cerberus buildall       --- build all watched applications

    Version: #{Cerberus::VERSION}
    Cerberus Home Path: "#{Cerberus::HOME}"
  }.gsub("\n    ","\n")
end