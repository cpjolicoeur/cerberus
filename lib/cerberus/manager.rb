require 'action_mailer'
require 'fileutils'
require 'cerberus/utils'

module Cerberus
  HOME = File.expand_path('~/.cerberus')

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
      config_name = "#{HOME}/config/#{options[:application_name]}.yml"
      say "Application #{options[:application_name]} already present in Cerberus" if File.exists?(config_name)
      File.open(config_name, 'w') {|f|
        YAML::dump(config, f)
      }

      puts "Application '#{options[:application_name]}' was successfully added to Cerberus"
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

      options[:application_root] = "#{HOME}/work/#{application_name}/sources"
      @checkout = Checkout.new(options[:application_root], options)
      @checkout.update!
    end
 
    def run
      previous_status = @status.recall
      
      state = 
      if checkout.has_changes?
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
          Notifier.deliver_failure(build, @options)
        when :revived
          Notifier.deliver_revival(build, @options)
        when :broken
          Notifier.deliver_broken(build, @options)
        when :unchanged, :succesful
          # Smile, be happy, it's all good
      end 
    end
 
    private
      def make
        Dir.chdir @options[:application_root]
        @output = `#{@options[:bin_path]}rake #{@options[:task_name]} RAILS_ENV=test`
        make_successful?
      end
      
      def make_successful?
        $?.exitstatus == 0
      end
  end
  
  class Checkout
    def initialize(path, options = {})
      @path, @options = path, options
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
        `#{@options[:env_command]}#{command} #{pre_parameters} "#{@path}" #{parameters}`
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
    def self.setup_context
      config_file = "#{HOME}/config.yml"
      File.open(config_file, 'w'){ |f| YAML::dump({'mail'=>''}, f) } unless test(?f,config_file)

      ActionMailer::Base.delivery_method = :smtp
      c = YAML::load(IO.read(config_file))['mail'] || {}
      mail_config = {}
      c.each_pair{|key,value| mail_config[key.to_sym]=value}

      ActionMailer::Base.server_settings = mail_config
    end

    def failure(build, options, sent_at = Time.now)
      @subject = "[#{options[:application_name]}] Build broken by #{build.checkout.last_author} (##{build.checkout.current_revision})"
      @body    = [ build.checkout.last_commit_message, build.output ].join("\n\n")

      @recipients, @from, @sent_on = options[:recipients], options[:sender], sent_at
    end
    
    def broken(build, options, sent_at = Time.now)
      @subject = "[#{options[:application_name]}] Build still broken (##{build.checkout.current_revision})"
      @body    = [ build.checkout.last_commit_message, build.output ].join("\n\n")

      @recipients, @from, @sent_on = options[:recipients], options[:sender], sent_at
    end
    
    def revival(build, options, sent_at = Time.now)
      @subject = "[#{options[:application_name]}] Build fixed by #{build.checkout.last_author} (##{build.checkout.current_revision})"
      @body    = [ build.checkout.last_commit_message ].join("\n\n")

      @recipients, @from, @sent_on = options[:recipients], options[:sender], sent_at
    end
  end
end