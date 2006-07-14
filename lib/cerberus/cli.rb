require 'cerberus/manager'
require 'cerberus/utils'
require 'cerberus/version'
require 'cerberus/constants'

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

        application_name = args[1]
        command = Cerberus::Build.new(application_name,
          :rake_task        => ENV['RAKE_TASK'] || '',
          :bin_path         => ENV['BIN_PATH']  || '',
          :application_name => args[1], 
          :recipients       => ENV['RECIPIENTS'], 
          :sender           => ENV['SENDER']
        )

        begin
          command.run
        rescue Exception => e
          File.open("#{HOME}/work/#{application_name}/error.log", File::WRONLY|File::APPEND|File::CREAT) {|f| 
            f.puts Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
            f.puts e.message
            f.puts e.backtrace.collect{|line| ' '*5 + line}
            f.puts "\n"
          }
        end
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