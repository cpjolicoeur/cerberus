require 'cerberus/manager'
require 'cerberus/utils'
require 'cerberus/constants'

module Cerberus
  class CLI
    def initialize(*args)
      say HELP if args.empty?

      command = args.shift

      cli_options = extract_options(args)

      case command
      when 'add'
        path = args.shift || Dir.pwd
        command = Cerberus::AddCommand.new(path, cli_options)
        command.run
      when 'remove'
        command = Cerberus::RemoveCommand.new(args.shift, cli_options)
        command.run
      when 'build'
        say HELP if args.empty?

        application_name = args.shift

        command = Cerberus::BuildCommand.new(application_name, cli_options)
        command.run
      when 'buildall'
        command = Cerberus::BuildAllCommand.new(cli_options)
        command.run
      when 'list'
        command = Cerberus::ListCommand.new(cli_options)
        command.run
      when 'status'
        command = Cerberus::StatusCommand.new(cli_options)
        command.run
      else
        say HELP
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
        when '--verbose', '-v'
          result[:verbose] = true
          args.delete(arg)
        end
      end

      result
    end
  end

  HELP = %{
    Cerberus is a lightweight command-line Continuous Integration tool for Ruby.

    Usage:
      cerberus add <URL>     --- add project from a repository to list watched of applications
      cerberus add <PATH>    --- add project from local path to list of watched applications
      cerberus remove <NAME> --- remove given project from cerberus
      cerberus build <NAME>  --- build watched application
      cerberus buildall      --- build all watched applications
      cerberus list          --- see the list of all watched applications
      cerberus status        --- see the current status of all cerberus projects

    Version: #{Cerberus::VERSION}
    Cerberus Path: "#{Cerberus::HOME}"
    Cerberus Homepage: http://cerberus.rubyforge.org
    }.gsub("\n    ", "\n")
end
