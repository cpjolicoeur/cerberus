require 'rubygems'
require 'action_mailer'
require 'fileutils'
require 'cerberus/utils'

module Cerberus
  HOME = File.expand_path(ENV['CERBERUS_HOME'] || '~/.cerberus')

  class Add
    include Cerberus::Utils

    def initialize(path, options = {})
      checkout = Checkout.new(path, options)
      say "Can't find any svn application under #{path}" unless checkout.url

      options[:application_name] ||= File.basename(path)
      config = {
        'url' => checkout.url,
        'recipients' => options[:recipients]
      }

      FileUtils.mkpath "#{HOME}/config"

      config_file = "#{HOME}/config.yml"
      File.open(config_file, 'w') do |f| 
        default_mail_config = {'mail'=>{'address'=>'', 'user_name'=>'', 'password'=>''}}
        YAML::dump(default_mail_config, f)
      end unless test(?f,config_file)
      
      config_name = "#{HOME}/config/#{options[:application_name]}.yml"
      say "Application #{options[:application_name]} already present in Cerberus" if File.exists?(config_name)
      File.open(config_name, 'w') {|f| YAML::dump(config, f) }

      puts "Application '#{options[:application_name]}' was successfully added to Cerberus" unless options[:quiet]
    end
  end

  class Build
    include Cerberus::Utils
    attr_reader :output, :success, :checkout, :status

    def initialize(application_name, options = {})
      config_name = "#{HOME}/config/#{application_name}.yml"
      say "Project #{application_name} does not present in Cerberus" unless File.exists?(config_name)

      @options  = options
      YAML::load(IO.read(config_name)).each_pair{|k,v| @options[k.to_sym] = v}

      @status = Status.new("#{HOME}/work/#{application_name}/status.log")

      @options[:application_root] = "#{HOME}/work/#{application_name}/sources"
      @checkout = Checkout.new(options[:application_root], options)
      @checkout.update!
    end
 
    def run
      
      state = 
      if checkout.has_changes? or not @status.recall
        previous_status = @status.recall

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
          # Smile, be happy, it's all good
      end 
    end
 
    private
      def make
        Dir.chdir @options[:application_root]
        ext = os() == :windows ? '.bat' : ''

        silence_stream(STDERR) {
          @output = `#{@options[:bin_path]}rake#{ext} #{@options[:task_name]} RAILS_ENV=test`
        }
        make_successful?
      end
      
      def make_successful?
         $?.exitstatus == 0 and not @output.include?('Test failures')
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
      execute("svn log", " -rHEAD -v")
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
        config_file = "#{HOME}/config.yml"
        c = YAML::load(IO.read(config_file))['mail'] || {}
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