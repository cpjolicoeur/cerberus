require 'fileutils'

require 'cerberus/utils'
require 'cerberus/constants'
require 'cerberus/config'
require 'cerberus/latch'

module Cerberus
  class AddCommand
    EXAMPLE_CONFIG = File.expand_path(File.dirname(__FILE__) + '/config.example.yml')
    include Cerberus::Utils

    def initialize(path, cli_options = {})
      @path, @cli_options = path, HashWithIndifferentAccess.new(cli_options)
    end

    def run
      scm_type = @cli_options[:scm] || 'svn'
      scm = Cerberus::SCM.get(scm_type).new(@path, Config.new(nil, @cli_options))
      say "Can't find any #{scm_type} application under #{@path}" unless scm.url

      application_name = @cli_options[:application_name] || extract_project_name(@path)

      create_example_config
      
      config_name = "#{HOME}/config/#{application_name}.yml"
      say "Application #{application_name} already present in Cerberus" if File.exists?(config_name)

      app_config = { 'scm' => {
          'url' => scm.url,
          'type' =>  scm_type },
          'publisher' => {'mail' => {'recipients' => @cli_options[:recipients]}}
      }
      app_config['builder'] = {'type' => @cli_options[:builder]} if @cli_options[:builder]
      dump_yml(config_name, app_config)
      puts "Application '#{application_name}' has been added to Cerberus successfully" unless @cli_options[:quiet]
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
                      :log => {:enable => true}
                     }

    def initialize(application_name, cli_options = {})
      unless File.exists?("#{HOME}/config/#{application_name}.yml")
        say "Project '#{application_name}' does not present in Cerberus. Type 'cerberus list' to see the list of all active projects."
      end

      app_root = "#{HOME}/work/#{application_name}"
      
      def_options = {:application_root => app_root + '/sources', :application_name => application_name} #pseudo options that stored in config. Could not be set in any config file not through CLI
      @config = Config.new(application_name, cli_options.merge(def_options))
      @config.merge!(DEFAULT_CONFIG, false)

      @status = Status.new("#{app_root}/status.log")

      scm_type = @config[:scm, :type]
      @scm = SCM.get(scm_type).new(@config[:application_root], @config)
      say "Client for SCM '#{scm_type}' does not installed" unless @scm.installed?

      builder_type = get_configuration_option(@config[:builder], :type, :rake)
      @builder = Builder.get(builder_type).new(@config)
    end
 
    def run
      begin
        Latch.lock("#{HOME}/work/#{@config[:application_name]}/.lock", :lock_ttl => 2 * LOCK_WAIT) do
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

          #Save logs to directory
          if @config[:log, :enable] and state != :unchanged
            log_dir = "#{HOME}/work/#{@config[:application_name]}/logs/"
            FileUtils.mkpath(log_dir)

            time = Time.now.strftime("%Y%m%d%H%M%S")
            file_name = "#{log_dir}/#{time}-#{state.to_s}.log"
            body = [ scm.last_commit_message, builder.output ].join("\n\n")
            IO.write(file_name, body)
          end

          #send notifications
          if [:failure, :broken, :revival, :setup].include?(state)
            active_publishers = get_configuration_option(@config[:publisher], :active, 'mail')
            active_publishers.split(/\W+/).each do |pub|
              raise "Publisher have no configuration: #{pub}" unless @config[:publisher, pub]
              Publisher.get(pub).publish(state, self, @config)
            end
          end
        end #lock
      rescue Exception => e
        if ENV['CERBERUS_ENV'] == 'TEST'
          raise e
        else
          File.open("#{HOME}/error.log", File::WRONLY|File::APPEND|File::CREAT) do |f| 
            f.puts Time.now.strftime("%a, %d %b %Y %H:%M:%S [#{@config[:application_name]}] --  #{e.class}")
            f.puts e.message unless e.message.blank?
            f.puts e.backtrace.collect{|line| ' '*5 + line}
            f.puts "\n"
          end
        end
      end
    end

  private
    def get_configuration_option(hash, defining_key = nil, default_option = nil)
      if hash
        return hash[defining_key] if hash[defining_key]
        return hash.keys[0] if hash.size == 1
      end
      return default_option
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
        if @already_waited or not t.join(LOCK_WAIT)
          t.kill
          @already_waited = true
        end
      end
    end
  end

  class ListCommand
    def initialize(cli_options = {})
    end

    def run
      projects = Dir["#{HOME}/config/*.yml"]
      if projects.empty?
        puts "There are no any active projects" 
      else
        puts "List of active projects:"

        projects.each do |fn|
          fn =~ %r{#{HOME}/config/(.*).yml}

          puts "  * #{$1}"
        end

        puts "\nType 'cerberus build PROJECT_NAME' to build any of these projects"
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
      return false unless File.exists?(@path)
      value = File.read(@path)
      value.empty? ? false : value.to_sym
    end
  end
end

module Cerberus
  module SCM
    TYPES = {
      :svn => 'SVN', #Cerberus::SCM
      :darcs => 'Darcs',
      :perforce => 'Perforce'
    }

    def self.get(type)
       class_name = TYPES[type.to_sym]
       say "SCM #{type} not supported" unless class_name
       require "cerberus/scm/#{type}"
       const_get(class_name)
    end
  end

  module Publisher
    TYPES = {
      :mail => 'Mail', #Cerberus::Publisher
      :jabber => 'Jabber',
      :irc => 'IRC',
      :rss => 'RSS',
      :campfire => 'Campfire'
    }

    def self.get(type)
       class_name = TYPES[type.to_sym]
       say "Publisher #{type} not supported" unless class_name
       require "cerberus/publisher/#{type}"
       const_get(class_name)
    end
  end

  module Builder
    TYPES = {
      :maven2 => 'Maven2', #Cerberus::Builder
      :rake => 'Rake',
      :rant => 'Rant',
      :bjam => 'Bjam'
    }

    def self.get(type)
       class_name = TYPES[type.to_sym]
       say "Builder #{type} not supported" unless class_name
       require "cerberus/builder/#{type}"
       const_get(class_name)
    end
  end
end
