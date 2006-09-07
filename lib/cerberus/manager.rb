require 'rubygems'
require 'fileutils'

require 'cerberus/utils'
require 'cerberus/constants'
require 'cerberus/config'

require 'cerberus/publisher/mail'
require 'cerberus/publisher/jabber'
require 'cerberus/publisher/irc'
require 'cerberus/publisher/rss'
require 'cerberus/scm/svn'

module Cerberus
  SCM_TYPES = {
    :svn => Cerberus::SCM::SVN
  }

  PUBLISHER_TYPES = {
    :mail => Cerberus::Publisher::Mail,
    :jabber => Cerberus::Publisher::Jabber,
    :irc => Cerberus::Publisher::IRC,
    :rss => Cerberus::Publisher::RSS
  }

  BUILDER_TYPES = {
    :maven2 => Cerberus::Builder::Maven2,
    :rake => Cerberus::Builder::Rake
  }

  class AddCommand
    EXAMPLE_CONFIG = File.expand_path(File.dirname(__FILE__) + '/config.example.yml')
    include Cerberus::Utils

    def initialize(path, cli_options = {})
      @path, @cli_options = path, HashWithIndifferentAccess.new(cli_options)
    end

    def run
      scm_type = @cli_options[:scm] || 'svn'
      say "SCM #{scm_type} not supported" unless SCM_TYPES[scm_type.to_sym]
      scm = SCM_TYPES[scm_type.to_sym].new(@path, @cli_options)
      say "Can't find any #{scm_type} application under #{@path}" unless scm.url

      application_name = @cli_options[:application_name] || extract_project_name(@path)

      create_example_config
      
      config_name = "#{HOME}/config/#{application_name}.yml"
      say "Application #{application_name} already present in Cerberus" if File.exists?(config_name)

      app_config = { 'scm' => {
          'url' => scm.url,
          'type' =>  scm_type },
          'publisher' => {'mail' => {'recipients' => @cli_options[:recipients]}},
          'builder' => {'type' => @cli_options[:builder]}
      }
      dump_yml(config_name, app_config)
      puts "Application '#{application_name}' was successfully added to Cerberus" unless @cli_options[:quiet]
    end

    private
    def extract_project_name(path)
      path = File.expand_path(path) if test(?d, path)
      File.basename(path).strip
    end

    def create_example_config
      FileUtils.mkpath(HOME) unless test(?d, HOME)
      FileUtils.cp(EXAMPLE_CONFIG, CONFIG_FILE) unless test(?f, CONFIG_FILE)
    end
  end

  class BuildCommand
    include Cerberus::Utils
    attr_reader :builder, :success, :scm, :status

    DEFAULT_CONFIG = {:scm => {:type => 'svn'}, 
                      :builder => {:type => 'rake'}, 
                      :publisher => {:active => 'mail'}, 
                      :log => {:enable => true}
                     }

    def initialize(application_name, cli_options = {})
      unless File.exists?("#{HOME}/config/#{application_name}.yml")
        say "Project #{application_name} does not present in Cerberus"
      end

      app_root = "#{HOME}/work/#{application_name}"
      
      def_options = {:application_root => app_root + '/sources', :application_name => application_name} #pseudo options that stored in config. Could not be set in any config file not through CLI
      @config = Config.new(application_name, cli_options.merge(def_options))
      @config.merge!(DEFAULT_CONFIG, false)

      @status = Status.new("#{app_root}/status.log")

      scm_type = @config[:scm, :type]
      @scm = SCM_TYPES[scm_type.to_sym].new(@config[:application_root], @config)

      builder_type = @config[:builder, :type]
      @builder = BUILDER_TYPES[builder_type.to_sym].new(@config)
    end
 
    def run
      begin
        previous_status = @status.recall
        @scm.update!

        state = 
        if @scm.has_changes? or @config[:force] or not previous_status
          if status = @builder.run
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
          active_publishers = @config[:publisher, :active]
          active_publishers.split(/\W+/).each do |pub|
            raise "Publisher have no configuration: #{pub}" unless @config[:publisher, pub]
            clazz = PUBLISHER_TYPES[pub.to_sym]
            raise "There is no such publisher: #{pub}" unless clazz
            silence_stream(STDOUT) { #some of publishers like IRC very noisy
              clazz.publish(state, self, @config)
            }
          end
        end

        #Save logs to directory
        if @config[:log, :enable] and state != :unchanged
          log_dir = "#{HOME}/work/#{@config[:application_name]}/logs/"
          FileUtils.mkpath(log_dir)

          time = Time.now.strftime("%Y%m%d%H%M%S")
          file_name = "#{log_dir}/#{time}-#{state.to_s}.log"
          body = [ scm.last_commit_message, builder.output ].join("\n\n")
          IO.write(file_name, body)
        end
      rescue Exception => e
        if ENV['CERBERUS_ENV'] == 'TEST'
          raise e
        else
          File.open("#{HOME}/work/#{@config[:application_name]}/error.log", File::WRONLY|File::APPEND|File::CREAT) do |f| 
            f.puts Time.now.strftime("%a, %d %b %Y %H:%M:%S  --  #{e.class}")
            f.puts e.message unless e.message.blank?
            f.puts e.backtrace.collect{|line| ' '*5 + line}
            f.puts "\n"
          end
        end
      end
    end
  end

  class BuildAllCommand
    def initialize(cli_options = {})
      @cli_options = cli_options
    end

    def run
      threads = []
      Dir["#{HOME}/config/*.yml"].each do |fn|
        fn =~ %r{#{HOME}/config/(.*).yml}
        application_name = $1

        command = Cerberus::BuildCommand.new(application_name, @cli_options)
        threads << Thread.new { command.run }
      end

      @already_waited = false
      threads.each do |t| 
        if @already_waited or not t.join(30.minutes)
          t.kill
          @already_waited = true
        end
      end
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
