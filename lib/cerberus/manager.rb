require 'rubygems'
require 'action_mailer'
require 'fileutils'

require 'cerberus/utils'
require 'cerberus/constants'

module Cerberus
  class Add
    include Cerberus::Utils

    def initialize(path, options = {})
      @path, @options = path, options
    end

    def run
      checkout = Checkout.new(@path, @options)
      say "Can't find any svn application under #{@path}" unless checkout.url

      @options[:application_name] ||= File.basename(@path).strip
      config = {
        'url' => checkout.url,
        'recipients' => @options[:recipients]
      }

      create_default_config
      
      config_name = "#{HOME}/config/#{@options[:application_name]}.yml"
      say "Application #{@options[:application_name]} already present in Cerberus" if File.exists?(config_name)

      dump_yml(config_name, config)
      puts "Application '#{@options[:application_name]}' was successfully added to Cerberus" unless @options[:quiet]
    end

    private
    def create_default_config
      default_mail_config = {'mail'=>{'address'=>'', 'user_name'=>'', 'password'=>''}}
      dump_yml(CONFIG_FILE, default_mail_config, false)
    end
  end

  class Build
    include Cerberus::Utils
    attr_reader :output, :success, :checkout, :status

    def initialize(application_name, options = {})
      config_name = "#{HOME}/config/#{application_name}.yml"
      say "Project #{application_name} does not present in Cerberus" unless File.exists?(config_name)

      @options  = options
      load_yml(config_name).each_pair{|k,v| @options[k.to_sym] = v}

      @status = Status.new("#{HOME}/work/#{application_name}/status.log")

      @options[:application_root] = "#{HOME}/work/#{application_name}/sources"
      @checkout = Checkout.new(options[:application_root], options)
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
          Notifier.deliver_failure(self, @options)
        when :revived
          Notifier.deliver_revival(self, @options)
        when :broken
          Notifier.deliver_broken(self, @options)
        when :unchanged, :succesful
          Notifier.deliver_setup(self, @options) unless previous_status  #If it first time we build application then let everyone to know that we have Cerberus now

          # Smile, be happy, it's all good
      end unless @options[:quiet]
    end
 
    private
      def make
        Dir.chdir @options[:application_root]

        silence_stream(STDERR) {
          @output = `#{@options[:bin_path]}#{choose_rake_exec()} #{@options[:task_name]} RAILS_ENV=test`
        }
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
      load_config

      @subject = "[#{options[:application_name]}] " + @subject
      @body    = [ build.checkout.last_commit_message, build.output ].join("\n\n")

      @recipients, @sent_on = options[:recipients], Time.now

      @from = options[:sender] || @mail_config[:sender] || "'Cerberus' <cerberus@example.com>"
      raise "Please specify recipient addresses for application '#{options[:application_name]}'" unless options[:recipients]
    end

    def load_config
      unless @mail_config
        c = load_yml(CONFIG_FILE)['mail'] || {}
        @mail_config = {}
        c.each_pair{|key,value| @mail_config[key.to_sym] = value}

        [:authentication, :delivery_method].each do |key|
          if @mail_config[key]
            @mail_config[key] = @mail_config[key].to_sym
          end
        end

        ActionMailer::Base.delivery_method = @mail_config[:delivery_method] if @mail_config[:delivery_method]
        ActionMailer::Base.server_settings = @mail_config
      end
    end
  end
end