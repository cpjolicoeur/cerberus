require 'rubygems'
require 'fileutils'

require 'cerberus/utils'
require 'cerberus/constants'
require 'cerberus/config'

require 'cerberus/notifier/email'

module Cerberus
  class Add
    include Cerberus::Utils

    def initialize(path, cli_options = {})
      @path, @config = path, Config.new(nil, cli_options)
    end

    def run
      checkout = Checkout.new(@path, @config)
      say "Can't find any svn application under #{@path}" unless checkout.url

      application_name = @config[:application_name] || extract_project_name(@path)

      create_default_config
      
      config_name = "#{HOME}/config/#{application_name}.yml"
      say "Application #{application_name} already present in Cerberus" if File.exists?(config_name)

      app_config = {
        'url' => checkout.url,
        'recipients' => @config[:recipients]
      }
      dump_yml(config_name, app_config)
      puts "Application '#{application_name}' was successfully added to Cerberus" unless @config[:quiet]
    end

    private
    def extract_project_name(path)
      path = File.expand_path(path) if test(?d, path)
      File.basename(path).strip
    end
    
    def create_default_config
      default_mail_config = 
        {'mail'=>
          { 'delivery_method'=>'smtp', 
            'address'=>'somserver.com', 
            'port' => 25, 
            'domain'=>'somserver.com', 
            'user_name'=>'secret_user', 
            'password'=>'secret_password',
            'authentication' => 'plain'
          }, 
          'sender' => "'Cerberus' <cerberus@example.com>"}
      dump_yml(CONFIG_FILE, default_mail_config, false)
    end
  end

  class Build
    include Cerberus::Utils
    attr_reader :output, :success, :checkout, :status

    def initialize(application_name, cli_options = {})
      unless File.exists?("#{HOME}/config/#{application_name}.yml")
        say "Project #{application_name} does not present in Cerberus"
      end

      app_root = "#{HOME}/work/#{application_name}"
      
      def_options = {:application_root => app_root + '/sources', :application_name => application_name} #pseudo options that stored in config. Could not be set in any config file not through CLI
      @config = Config.new(application_name, cli_options.merge(def_options))

      @status = Status.new("#{app_root}/status.log")

      @checkout = Checkout.new(@config[:application_root], @config)
    end
 
    def run
      begin
        previous_status = @status.recall
        @checkout.update!

        state = 
        if @checkout.has_changes? or not previous_status
          if status = make
            @status.keep(:succesful)
            case previous_status
            when :failed
              :revival
            when :succesful
              :succesful
            when false
              :setup
            end
          else
            @status.keep(:failed)
            previous_status == :failed ? :broken : :failure
          end
        else
          :unchanged
        end

        if [:failure, :broken, :revival, :setup].include?(state)
          Cerberus::Notifier::Email.notify(state, self, @config)
        end
      rescue Exception => e
        File.open("#{HOME}/work/#{@config[:application_name]}/error.log", File::WRONLY|File::APPEND|File::CREAT) do |f| 
          f.puts Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
          f.puts e.message
          f.puts e.backtrace.collect{|line| ' '*5 + line}
          f.puts "\n"
        end
      end
    end
 
    private
      def make
        Dir.chdir @config[:application_root]

        @output = `#{@config[:bin_path]}#{choose_rake_exec()} #{@config[:rake_task]} 2>&1`

        make_successful?
      end
      
      def make_successful?
         $?.exitstatus == 0 and not @output.include?('rake aborted!')
      end

      def choose_rake_exec
        ext = ['']

        if os() == :windows 
          ext << '.bat' << '.cmd'
        end

        ext.each{|e|
          begin
            out = `rake#{e} --version`
            return "rake#{e}" if out =~ /rake/
          rescue
          end
        }
      end
  end

  class BuildAll
    def initialize(cli_options = {})
      @cli_options = cli_options
    end

    def run
      Dir["#{HOME}/config/*.yml"].each do |fn|
        fn =~ %r{#{HOME}/config/(.*).yml}
        application_name = $1

        command = Cerberus::Build.new(application_name, @cli_options)
        command.run
      end
    end
  end

  
  class Checkout
    def initialize(path, options = {})
      raise "Path can't be nil" unless path

      @path, @options = path.strip, options
      @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
    end

    def update!
      if test(?d, @path + '/.svn')
        execute("svn cleanup") #TODO check first that it was locked
        @status = execute("svn update")
      else
        FileUtils.mkpath(@path) unless test(?d,@path)
        @status = execute("svn checkout", nil, @options[:url])
      end
    end

    def has_changes?
      @status =~ /[A-Z]\s+[\w\/]+/
    end

    def current_revision
      info['Revision'].to_i
    end
 
    def url
      info['URL']
    end
 
    def last_commit_message
      message = execute("svn log", "--limit 1 -v")
      #strip first line that contains command line itself (svn log --limit ...)
      if ((idx = message.index('-'*72)) != 0 )
        message[idx..-1]
      else
        message
      end
    end
 
    def last_author
      info['Last Changed Author']
    end

    private
      def info
        @info ||= YAML.load(execute("svn info"))
      end
      
      def execute(command, parameters = nil, pre_parameters = nil)
        `#{@options[:bin_path]}#{command} #{pre_parameters} #{@encoded_path} #{parameters}`
      end
  end

  class Status
    def initialize(path)
      @path = path
    end
    
    def keep(status)
      File.open(@path, "w+", 0777) { |file| file.write(status.to_s) }
    end
    
    def recall
      value = File.exists?(@path) ? File.read(@path) : false
      value.blank? ? false : value.to_sym
    end
  end
end
