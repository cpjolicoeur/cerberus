require 'rubygems'
require 'action_mailer'
require 'fileutils'

require 'cerberus/utils'
require 'cerberus/constants'
require 'cerberus/config'

module Cerberus
  class Add
    include Cerberus::Utils

    def initialize(path, cli_options = {})
      @path, @config = path, Config.new(nil, cli_options)
    end

    def run
      checkout = Checkout.new(@path, @config)
      say "Can't find any svn application under #{@path}" unless checkout.url

      application_name = @config[:application_name] || File.basename(@path).strip

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
          'sender' => 'Cerberus'}
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
      @checkout.update!
    end
 
    def run
      previous_status = @status.recall

      state = 
      if checkout.has_changes? or not previous_status
        if status = make
          @status.keep(:succesful)
          previous_status == :failed ? :revived : :succesful
        else
          @status.keep(:failed)
          previous_status == :failed ? :broken : :failed
        end
      else
        :unchanged
      end

      case state
        when :failed
          Notifier.deliver_failure(self, @config)
        when :revived
          Notifier.deliver_revival(self, @config)
        when :broken
          Notifier.deliver_broken(self, @config)
        when :unchanged, :succesful
          unless previous_status  #If it first time we build application then let everyone to know that we have Cerberus now
            Notifier.deliver_setup(self, @config)
          end

          # Smile, be happy, it's all good
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
  
  class Checkout
    def initialize(path, options = {})
      raise "Path can't be nil" unless path

      @path, @options = path.strip, options
      @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
    end

    def update!
      if test(?d, @path + '/.svn')
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

  class Notifier < ActionMailer::Base
    include Cerberus::Utils
    
    def failure(build, options)
      @subject = "Build broken by #{build.checkout.last_author} (##{build.checkout.current_revision})"
      send_message(build, options)
    end
    
    def broken(build, options)
      @subject = "Build still broken (##{build.checkout.current_revision})"
      send_message(build, options)
    end
    
    def revival(build, options)
      @subject = "Build fixed by #{build.checkout.last_author} (##{build.checkout.current_revision})"
      send_message(build, options)
    end

    def setup(build, options)
      @subject = "Cerberus set up for project (##{build.checkout.current_revision})"
      send_message(build, options)
    end

    private
    def send_message(build, options)
      mail_config = options[:mail] || {}
      ActionMailer::Base.delivery_method = mail_config[:delivery_method].to_sym if mail_config[:delivery_method]
      ActionMailer::Base.server_settings = mail_config

      @subject = "[#{options[:application_name]}] " + @subject
      @body    = [ build.checkout.last_commit_message, build.output ].join("\n\n")

      @recipients, @sent_on = options[:recipients], Time.now

      @from = options[:sender] || "'Cerberus' <cerberus@example.com>"
      raise "Please specify recipient addresses for application '#{options[:application_name]}'" unless options[:recipients]
    end
  end
end